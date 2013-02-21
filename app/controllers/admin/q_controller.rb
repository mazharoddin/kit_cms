class Admin::QController < KitController

  before_filter :load_client, :except=>[:index, :create]
  before_filter :check_user, :except=>[:index, :destroy, :create]
  before_filter :check_admin, :only=>[ :destroy, :create]

  def index
    if  current_user.admin?
      @clients = QClient.sys(_sid).order(:name).all
      @q_client = QClient.new
      render "index", :layout=>get_layout
    else
      @client = QClient.sys(_sid).where(:user_id=>current_user.id).first
      redirect_to "/admin/q/#{@client.id}"
    end
  end

  def destroy
    @client.destroy
    redirect_to "/admin/q", :notice=>"Client deleted"
  end

  def create
    @client = QClient.new(params[:q_client])
    @client.system_id = _sid
    @client.token = rand
    @client.auth_id = QClient.generate_random
    @client.auth_secret = QClient.generate_random
    @client.auth_method = "digest"
    @client.save

    @q_user = QUser.create(:system_id=>_sid, :q_client_id=>@client.id, :q_external_id=>0, :notification_method=>"twitter", :source=>1)

    QSubscription.create(:system_id=>_sid, :q_client_id=>@client.id, :topic=>"tweet", :q_user_id=>@q_user.id)
    redirect_to "/admin/q/#{@client.id}?auth=1", :notice=>"Created new client - now set up authentication"
  end

  def show
    if request.post?
      @event = QEvent.new(params[:q_event])
      @event.system_id = _sid
      @event.q_client = @client
      @event.save
      flash[:notice] = "Event created"
      redirect_to "/admin/q/#{@client.id}"
      return
    end
    @event = QEvent.new

    render "show", :layout=>get_layout
  end

  def klasses
    if request.put? || request.post?
      if params[:q_klass][:id]
        @q_klass = QKlass.sys(_sid).where(:id=>params[:q_klass][:id]).first
      else
        @q_klass = QKlass.new
        @q_klass.system_id = _sid
        @q_klass.q_client_id = @client.id
      end
      @q_klass.update_attributes(params[:q_klass])
      @q_klass.save
      redirect_to "/admin/q/#{@client.id}/klasses", :notice=>"Saved"
    else
      @q_klass = params[:klass_id] ? QKlass.sys(_sid).where(:id=>params[:klass_id]).first : QKlass.new
    end

    render "klasses", :layout=>get_layout
  end

  def sent
    render "sent", :layout=>get_layout
  end

  def users
    render "users", :layout=>get_layout
  end

  def events
    render "events", :layout=>get_layout
  end

  def subscriptions
    render "subscriptions", :layout=>get_layout
  end

  def update
    @client.update_attributes(params[:q_client])
    respond_with_bip(@client)
  end

  private
  def load_client
    @client = QClient.sys(_sid).where(:id=>params[:id]).first
  end

  def get_layout
    if user.admin?
      "cms"
    else
      "#{_sid}/#{Preference.get_cached(_sid, "queue_manager_layout") || "application"}"
    end      
  end

  def check_user
    return true if current_user.admin?
    return true if current_user && @client.user_id == current_user.id

    redirect_to "/"
  end

  def check_admin
    current_user && current_user.admin?

    redirect_to "/"
  end
end
