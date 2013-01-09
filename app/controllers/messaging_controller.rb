class MessagingController < GnricController

  before_filter :load_user, :except=>[:index]

  def load_user
    authenticate_user!
  end

  class Msg
    attr_accessor :conversation_id
    attr_accessor :sender
    attr_accessor :message
    attr_accessor :message_id

    def self.make(conversation_id, sender, message, message_id)
      m = Msg.new
      m.conversation_id = conversation_id
      m.sender = sender
      m.message = message
      m.message_id = message_id
      return m
    end
  end

  def game_start
    o = Opponent.where(:user_id=>params[:opponent_id]).where(:game_id=>params[:game_id]).first
    result = ""
    unless o
      render :js => "game_start_error('Opponent does not exist');"
      return
    end

    cu = Conversation.find_by_sql("select c.* from conversations c, conversation_users cu1, conversation_users cu2 where c.id = cu1.conversation_id and c.id = cu2.conversation_id and cu1.user_id = #{current_user.id} and cu2.user_id = #{o.user_id}")

    if cu.size>0
      render :js => "game_created(#{cu.first.id}, '#{cu.first.name}');"
      return
    end

    c = Conversation.new
    c.user_id = current_user.id
    c.name = current_user.display_name + "&" + o.user.display_name
    c.is_public = false
    c.game_id = o.game_id
    c.save
    cu = ConversationUser.new
    cu.user_id = current_user.id
    cu.conversation_name_for_this_user = o.user.display_name
    cu.conversation_id = c.id
    cu.save
    cu2 = ConversationUser.new
    cu2.user_id = o.user_id
    cu2.conversation_name_for_this_user = current_user.display_name
    cu2.conversation_id = c.id
    cu2.save
    Conversation.connection.execute("update conversation_users set updated_at = now() where id in (#{cu.id}, #{cu2.id})")
    render :js => "game_created(#{c.id},'#{c.name}');"
  end

  def game_availability
    o = Opponent.where(:user_id => current_user.id).where(:game_id=>params[:id]).first
    if params[:available]=="true"
      Opponent.create(:user_id=>current_user.id, :game_id=>params[:id]) unless o
    else
      o.destroy if o
    end
    render :js=>";"
  end

  def index
    get_conversations
    @conversations = Conversation.where(:is_public=>1).all
    @conversations += current_user.conversations if current_user
  end

  def show_conversation
    @conversation = Conversation.find_sys_id(_sid, params[:id])

    render "show_conversation", :layout=>false
  end

  @@invoke_count = 0

  def poll
    @@invoke_count += 1  
    current_user.heard_from!
    if Rails.env.development? || @@invoke_count > 10
      @@invoke_count = 0
      Conversation.flush
    end
    r = {}
    r[:conversations] =  build_response(ActiveSupport::JSON.decode(params[:conversations]))
    get_conversations
    r[:list] = @conversations.as_json(:only=>[:id, :name])

    if params[:selected_game_id]
      opponents = []
      # opponents who have been heard from in teh last minute, that aren't this user, up to 50
      Opponent.where(:game_id=>params[:selected_game_id]).joins(:user).where("users.last_heard_from > date_sub(now(), interval 1 minute)").includes(:user).order("opponents.updated_at desc").limit(50).where("opponents.user_id<>#{current_user.id}").each do |opponent|
        if Conversation.find_by_sql("select c.* from conversations c, conversation_users cu1, conversation_users cu2 where c.id = cu1.conversation_id and c.id = cu2.conversation_id and cu1.user_id = #{current_user.id} and cu2.user_id = #{opponent.user_id} and c.game_id = #{opponent.game_id}").size==0
          opponents <<   { :user_id=>opponent.user_id, :user_name=>opponent.display_name, :game_id=>opponent.game_id } 
        end
      end
      r[:opponents] = opponents
      r[:me_available] = Opponent.where(:game_id=>params[:selected_game_id]).where(:user_id=>current_user.id).count == 1 ? "true" : "false"
    else
      r[:opponents] = nil
    end

    render :json => r
  end

  def message
    conversation_id = params[:id]
    Message.create(:system_id=>_sid, :conversation_id=>params[:id], :user_id=>current_user.id, :message=>params[:message])
    render :json => nil
  end

  def build_response(requested_convos)
    conversations = []

    requested_convos.each do |id, convo_details|
      next unless convo_details
      current_user.conversations.where(:id=>convo_details["conversation_id"]).each do |conversation|
        messages = conversation.messages.order("id desc").where("id>#{convo_details["last_message"]}")
        messages = messages.limit(5) if convo_details["last_message"].to_i==0
        messages.reverse.each do |message| 
          conversations << Msg.make(conversation.id, current_user.display_name, message.display_message, message.id) 
        end
        ConversationUser.connection.execute("update conversation_users set last_seen_message_id = #{messages.last.id} where conversation_id = #{conversation.id} and user_id = #{current_user.id}") if messages.last
      end
    end

    return conversations
  end

  def suggest_game
    game = Game.new
    game.name = params[:suggestion_name]
    game.is_live = 0
    game.save
    render :js=>"thanks_for_suggestion();"
  end

  private 

  def get_conversations
    @conversations = Conversation.where(:is_public=>1).all
    @conversations += current_user.conversations if current_user
    @conversations.each do |convo|
      convo.messages_waiting = false
      last_message = convo.messages.order("id desc").limit(1).first
      if last_message
        cu = convo.conversation_users.where(:user_id=>current_user.id).first
        if cu && cu.last_seen_message_id == nil
          convo.name += "+"
        elsif cu && cu.last_seen_message_id && last_message.id > cu.last_seen_message_id
          convo.name += "+"
        end
      end
    end
  end

end
