include ActionView::Helpers::TextHelper

class ForumController < KitController
  before_filter :load_forum_user_options, :only => [:topic_index, :thread, :search, :add_post, :recent, :im_on, :favourites, :thread_last_unread, :index]

  before_filter :is_moderator
  before_filter :thread_order, :only=>[:topic_index]
  before_filter :post_order, :only=>[:thread]

  def test
    kit_render "test", :layout_o=>get_layout('index')
  end

  def moderate
    redirect_to "/users/sign_in" and return unless @mod
    @topic_posts = TopicPost.sys(_sid).order("id desc").where(:is_visible=>1).page(params[:page]).per(25)  
    kit_render "moderate", :layout_o=>get_layout('index')
  end

  def rate_post
    if TopicPostVote.where(:user_id=>current_user.id).where(:topic_post_id=>params[:id]).count > 0 
      render :js=>"rating_dupe(#{params[:id]})"
      return
    end
    TopicPostVote.create(:user_id=>current_user.id, :topic_post_id=>params[:id], :score=>params[:score]=='-1' ? -1 : 1)
    render :js=>"rating_done(#{params[:id]})"
  end

  def favourite_thread
    @thread = TopicThread.find_sys_id(_sid, params[:id])
    if @thread.is_favourited_by(current_user)
      @thread.users.delete(current_user)
      r = t("forum.favourite_thread")
    else
      @thread.users << current_user
      r = t("forum.un_favourite_thread")
    end

    render :text=>r
  end

  def move_thread
    thread = TopicThread.find_sys_id(_sid, params[:thread_id])
    topic = Topic.find_sys_id(_sid, params[:topic_id])
    if topic && thread
      thread.topic_id = params[:topic_id]
      thread.moderation_comment += "Thread moved to #{topic.name} by #{current_user.email} at #{Time.now}<br/>"
      thread.save
      Activity.add(_sid, "Moved #{link_to('thread',thread.link)} to topic '#{topic.name}'", current_user, 'Forums')    
    end

    redirect_to thread.link
  end

  def favourites
    @list_name = 'forum.favourites'
    if current_user
      @threads = current_user.topic_threads.page(params[:page]).per(@user_options.threads_per_page)
      @page_title = "Forum: Favourite Threads"
      @show_watch = true
      kit_render "thread_list", :layout_o=>get_layout('im-watching', ['im-watching', 'threads']) 
    else
      redirect_to "/users/sign_in"
    end
  end

  def im_on
    @list_name = 'forum.im_on'

    if current_user
      @page_title = "Forum: Threads I Posted To"
      @threads = TopicThread.im_on(current_user, @user_options.threads_per_page, @mod, params[:page])
      kit_render "thread_list", :layout_o=>get_layout('im-on', ['im-on', 'threads'])
    else
      redirect_to "/users/sign_in"
    end
  end

  def recent_posts
    @page_title = "Forum: Recent Posts"
    @posts = TopicPost.sys(_sid).order("id desc").where(:is_visible=>1).page(params[:page]).per(50)  
    respond_to do |format|
     format.rss { render "forum/post_list.rss" }
    end 
  end

  def recent
    @list_name = "forum.recent"
    @page_title = "Forum: Recent Threads"
    @threads = TopicThread.most_recent(current_user, @user_options.threads_per_page, @mod, params[:page])
    @destination_last = true
  
    respond_to do |format|
      format.html { kit_render "thread_list", :layout_o=>get_layout('recent', ['recent', 'threads']) }
      format.rss { render "forum/thread_list.rss" }
    end
  end

  def report

    unless current_user
      redirect_to "/users/sign_in"
      return
    end
    @post = TopicPost.sys(_sid).where(:id=>params[:id]).first
    unless @post
      redirect_to "/forums"
      return
    end

    if request.post?
      post_report = PostReport.create(:user_id=>current_user.id, :topic_post_id=>@post.id, :comment=>params[:body])
      Activity.add(_sid,"User '#{current_user.email} reported post titled '#{@post.topic_thread.title}' by '#{ @post.created_by_user.email }'", current_user, "Users")

      Notification.report_post_admin(post_report, _sid).deliver
      flash[:notice] = "Thanks for reporting the post.  We'll take a look and may get back to you if necessary."
      redirect_to @post.link
      return
    end 

    kit_render "report", :layout_o=>get_layout('report')
  end

  def index
    categories = TopicCategory.sys(_sid).order(:display_order).includes({:topics=>[{:last_post=>[:created_by_user, {:topic_thread=>:topic}]},{:last_thread=>:created_by_user}]})
    categories = categories.where(:url=>params[:category]) if params[:category]
    @categories = categories.all
    @page_title = "Forums"
    @canonical_tag = "/forums"
    kit_render "index", :layout_o=>get_layout('index')
  end

  def search
    system_id = _sid
    if params[:for]
      original_search_for = params[:for]
      search_for = original_search_for.clone
      if search_for =~ /user\:\"([^\"]+)\"/i
        display_name = $1
        search_for.slice!(/user\:\"([^\"]+)\"/i)
        params[:for] = search_for
      end
      display_name = params[:display_name] if params[:display_name].not_blank?
      params[:display_name] = display_name
      search_fields = []
      indexes = []
      search_size = (params[:per] || "25").to_i
      the_page = (params[:page] || "1").to_i 
      log = logger

      [ "TopicPost", "TopicThread" ].each do |model|
        indexes << "kit_#{app_name.downcase}_#{model.tableize}"
        KitIndexed.indexed_columns(model).collect { |ic|
          search_fields << ic[:name] if ic[:user]
        }
      end

      search = Tire.search indexes.join(',') do 
        query do
          boolean do 
            if search_for.not_blank?
              must do 
                string search_for, :fields=>search_fields.uniq
              end
            end
            if display_name.not_blank?
              must do
                string display_name, :default_field=>:created_by_user_display_name 
              end
            end
          end
        end
        filter :term, :system_id=>system_id
        unless @mod
          filter :term, :is_visible=>1 
        end
        from (the_page-1)*search_size 
        size search_size
      end

      @results = search.results
    else
      @results = nil
    end

    kit_render "search", :layout_o=>get_layout('search')
  end

  def topic_index
    name = params[:topic]   
    @topic = load_topic(name)
    if @topic==nil
      # old style forum names which begin with a numebr?
      if params[:topic] =~ /^(\d+)\-(.*)$/
        load_topic($2)
      end
    end

    if @topic==nil 
      redirect_to "/forums", :notice=>"Topic not found"
      return
    end

    @post = TopicPost.new
    @threads = TopicThread.sys(_sid).where(:topic_id=>@topic.id).order("last_post_at " + @thread_order).includes([:topic]).page(params[:page]).per(@user_options.threads_per_page)

    @threads = @threads.where(:is_visible=>1) unless @mod  
    unless level_okay(@topic.read_access_level) 
      logger.debug "Required level is #{@topic.read_access_level} but current level is #{current_user ? current_user.forum_level : 'not logged in'}"
      redirect_to "/forums" 
      return
    end
    @page_title = "Forums: #{@topic.name}"
    @canonical_tag = "/forums/#{@topic.url}"
    @meta_description = "Forums"
    kit_render "topic_index", :layout_o=>get_layout('threads')
  end

  def category_topic_list
    @thread = TopicThread.find(params[:id])
    render "category_topic_list", :layout=>false
  end

  def thread_last_unread
    @thread = TopicThread.where(:id=>params[:id]).first
    if @thread==nil 
      redirect_to "/forums"  , :notice=>"Can't find that thread"
      return
    end
    redirect_to @thread.link_latest_unread(current_user, @user_options, @mod)
  end

  def thread
    # topic id name
    @thread = TopicThread.where(:id=>params[:id])
                .includes([:topic, :created_by_user, :last_post_by_user])
                .first
    if @thread==nil
      redirect_to "/forums"  , :notice=>"Can't find that thread"
      return
    end
    @thread.update_attributes(:view_count => @thread.view_count ? @thread.view_count+1 : 1)
    @post = TopicPost.new
    @posts = TopicPost.sys(_sid).where(:topic_thread_id => @thread.id).includes(:topic_post_edits).order("id " + @post_order)
    @posts = @posts.includes(:created_by_user)
    @posts = @posts.where(:is_visible=>1) unless @mod

    params[:latest] = nil

    @posts = @posts.page(params[:page]).per(@user_options.posts_per_page)

    if @posts.size==0
      redirect_to @thread.topic.link 
      return 
    end
    
    users = {}
    @posts.each { |p| users[p.created_by_user.id] = p.created_by_user }
    User.load_forum_attributes(_sid, users)

    current_user.topic_post_votes.where("topic_post_id in (#{@posts.map {|p| p.id }.join(',')})").each do |tpv|
      @posts.each do |post|
        if tpv.topic_post_id == post.id
          post.already_voted = true
          break
        end
      end
    end if current_user #&& @posts.size>0

    @show_mini_profile = Preference.get_cached(_sid, "forum_show_mini_profile")=="true"

    if current_user  && (@posts.last!=nil && @posts.last.id!=nil && current_user.id!=nil && @thread.id!=nil)
      ThreadView.connection.execute("insert into thread_views (user_id, topic_thread_id, topic_post_id) values (#{current_user.id}, #{@thread.id}, #{@posts.last.id}) on duplicate key update topic_post_id = greatest(topic_post_id, #{@posts.last.id});")
      if ttu = @thread.topic_thread_users.where(:user_id=>current_user.id).first
        ttu.update_attributes(:email_sent=>nil)
      end
    end

    unless level_okay(@thread.topic.read_access_level)
      redirect_to "/forums" 
      return
    end
    
    unless @mod || (@thread.is_visible==1 && @thread.topic.is_visible==1) 
      redirect_to "/forums" 
      return
    end

    @meta_description = "Forums: #{@thread.topic.name} - #{@thread.title}"
    @page_title = "#{@thread.topic.name} - #{@thread.title}"
    @canonical_tag = @thread.link

    kit_render "thread", :layout_o=>get_layout('posts')
  end

  def preview
    post = TopicPost.new(:raw_body=>params[:body], :created_by_user=>current_user, :is_visible=>true)

    post.update_body

    kit_render :partial=>"post_preview", :locals=>{:post=>post}
  end

  def add_post
    return unless anti_spam_okay?
    return unless sanity_check_okay?
    return unless check_post_rate?

    @thread = TopicThread.where(:id=>params[:id]).first
    redirect_to "/forums" and return  unless level_okay(@thread.topic.write_access_level)

    if @thread.is_locked? && !can?(:moderate, self)  
      flash[:notice] = "You can't post on this thread because it has been locked by a moderator"
      redirect_to @thread.link and return
    end

    if !@thread.is_visible? && !can?(:moderate, self)
      flash[:notice] = "You can't post on this thread because it has been removed by a moderator"
      redirect_to "/forums" and return
    end

    @post = TopicPost.new

    if params[:topic_post][:body] && params[:topic_post][:body].strip.length<2
      flash[:form_message] = "Your message must be at least 2 characters"            
      kit_render "thread", :layout_o=>get_layout('thread')
      return
    end

    @post.topic_thread_id = @thread.id
    @post.created_by_user_id = current_user.id
    @post.created_by_user_display_name = current_user.display_name
    @post.is_visible = 1
    @post.moderation_comment = ''
    @post.raw_body = params[:topic_post][:body]    
    @post.system_id = _sid
    @post.kit_session_id = session_id

    @post.ip = request.remote_ip
    if @post.save
      @thread.post_count += 1
      @thread.last_post_by_user_id = current_user.id
      @thread.last_post_by_user_display_name = current_user.display_name
      @thread.last_post_at = Time.now
      @thread.save
      @thread.topic.post_count += 1 rescue 1
      @thread.topic.last_thread_id = @thread.id
      @thread.topic.last_post_at = Time.now
      @thread.topic.last_post_id = @post.id
      @thread.topic.save
      @post.update_postnumber
    end

    redirect_to @thread.link_for_post(@post.id, @user_options, @mod)
  end

  def comments
    redirect_to "/forums" and return unless can?(:moderate, self)    
    @post = TopicPost.sys(_sid).where(:id=>params[:id]).first

    kit_render :text=>@post.moderation_comment
  end

  def thread_comment
    redirect_to "/forums" and return unless can?(:moderate, self)  

    @thread = TopicThread.where(:id=>params[:id]).first
    @thread.thread_comment = params[:thread][:thread_comment]
    @thread.moderation_comment ||= ''
    @thread.moderation_comment += "Thread comment added by #{current_user.email} at #{Time.now}<br/>"
    @thread.save
    Activity.add(_sid,"Added Thread Comment #{link_to(@thread.thread_comment,@thread.link)}'", current_user, 'Forums')    

    redirect_to @thread.link
  end

  def topic_comment
    redirect_to "/forums" and return unless can?(:moderate, self)  

    @topic = Topic.sys(_sid).where(:id=>params[:id]).first
    @topic.topic_comment = params[:topic][:topic_comment]
    @topic.save

    redirect_to @topic.link
  end

  def create_page_thread
    @topic = Topic.sys(_sid).where(:id=>Preference.getCached(_sid, 'topic_for_article_discussion')).first
    @post = TopicPost.new
    @threads = nil
    @page_id = params[:page_id] 
    @about_page_title = Page.find_sys_id(_sid, @page_id).title
    kit_render "topic_index", :layout_o=>get_layout('threads')
  end

  def create_thread
    return unless anti_spam_okay?
    return unless sanity_check_okay?
    return unless check_post_rate?

    @topic = Topic.sys(_sid).where(:url=>params[:topic]).first
    redirect_to "/forums" and return unless level_okay(@topic.write_access_level) && @topic.is_open? && @topic.is_visible?

    @post = TopicPost.new
    @post.raw_body = params[:topic_post][:body]

    if @post.raw_body.strip.length<2
      flash[:form_message] = "Your message must be at least 2 characters"      
      kit_render "topic_index", :layout_o=>get_layout('threads')
      return
    end
    if params[:topic_post][:title].strip.length<2
      flash[:form_message] = "Title must be at least 4 characters"
      kit_render "topic_index", :layout_o=>get_layout('threads')
      return
    end
    @post.system_id = _sid
    @post.created_by_user_id = current_user.id
    @post.created_by_user_display_name = current_user.display_name
    @thread = TopicThread.new
    @thread.topic_id = @topic.id
    @thread.created_by_user_id = current_user.id
    @thread.title = params[:topic_post][:title]
    @thread.moderation_comment = ''
    @thread.last_post_by_user_id = current_user.id
    @thread.last_post_by_user_display_name = current_user.display_name
    @thread.last_post_at = Time.now
    @thread.post_count = 1
    @thread.is_locked = 0
    @thread.is_sticky = 0
    @thread.locked_statement = ''
    @thread.is_visible = 1
    @thread.view_count = 0
    @thread.heat = 0
    @thread.system_id = _sid
    @thread.kit_session_id = session_id
    @thread.save
    @post.topic_thread_id = @thread.id
    @post.ip = request.remote_ip
    @post.is_visible = 1
    @post.kit_session_id = session_id
    @post.post_number = 1
    @post.save
    @topic.last_post_at = Time.now
    @topic.thread_count = @topic.thread_count + 1 rescue 1
    @topic.post_count = @topic.post_count + 1 rescue 1
    @topic.last_thread_id = @thread.id
    @topic.save
    @thread.first_post_id = @post.id
    @thread.save

    if params[:page_id].not_blank?
      PageThread.create(:page_id=>params[:page_id], :topic_thread=>@thread) 
    end

    Activity.add(_sid, "Created Thread '#{link_to(@thread.title,@thread.link)}'", current_user, 'Forums')

    redirect_to @thread.link 
  end

  def lock_thread
    @thread = TopicThread.where(:id=>params[:id]).first
    render :js=>";" and return unless can?(:moderate, self)
    @thread.is_locked =params[:lock]
    @thread.moderation_comment += (@thread.is_locked==0 ? "Locked" : "Unlocked") + " by #{current_user.email} at #{Time.now}<br/>"
    @thread.save

    if params[:lock]=="0"
      render :js=>"$('.unlocked').show(); $('.locked').hide(); $('#locked_warning').hide(); $('#post_message').show();"
      return
    else
      render :js=>"$('.unlocked').hide(); $('.locked').show();  $('#locked_warning').show(); $('#post_message').hide();"
      return
    end

  end

  def delete_thread
    @thread = TopicThread.where(:id=>params[:id]).first
    redirect_to "/forums" and return unless can?(:moderate, self)  

    @thread.is_visible=params[:undelete] ? 1 : 0
    @thread.moderation_comment += (@thread.is_visible==0 ? "Deleted" : "Undeleted") + " by #{current_user.email} at #{Time.now}<br/>"
    @thread.save

    if params[:undelete]!=1 && @thread.topic.last_thread_id == @thread.id 
      new_last = @thread.topic.topic_threads.where("topic_threads.id <> #{@thread.id}").where("topic_threads.is_visible = 1").order(:id).last
      if new_last
        @thread.topic.update_attributes(:last_thread_id=>new_last.id, :last_post_at=>new_last.topic_posts.order(:id).last.created_at)
      else
        @thread.topic.update_attributes(:last_thread_id=>nil, :last_post_at=>nil)
      end
    end 
    if request.xhr?
      render :js=>"done_delete(#{@thread.id}, #{@thread.is_visible? ? 1 : 0});" and return
    else
      redirect_to @thread.topic.link and return 
    end

  end

  def delete_post
    @post = TopicPost.sys(_sid).where(:id=>params[:id]).first
    redirect_to "/forums" and return unless can?(:moderate, self)

    @post.mark_as_deleted(current_user, params[:delete].to_i == 0) 
    if @post.is_visible==0
      topic = @post.topic_thread.topic
      if @post.id == topic.last_post_id
        new_last = @post.topic_thread.topic_posts.order("id desc").where("is_visible = 1").first
        unless new_last 
          last_thread = topic.topic_threads.order("id desc").where("is_visible = 1").first
          new_last = last_thread.topic_posts.order("id desc").where("is_visible = 1").first
        end
        if new_last
          topic.last_post_id= new_last.id
          topic.last_post_at = new_last.created_at
          topic.post_count ||= 1
          topic.post_count -= 1
          topic.save 
        end
      end
    end

    if params[:inc]
      @post.created_by_user.spam_points ||= 0
      @post.created_by_user.spam_points += 1 
      @post.created_by_user.save
    end

    if params[:status]
      @post.created_by_user.forum_status ||= 0
      @post.created_by_user.forum_status += 1
      @post.created_by_user.save
    end

    if params[:ban]
      @post.created_by_user.ban!(current_user)
    end

    if params[:delete_all]
      Activity.add(_sid, "Deleted all posts for user '#{@post.created_by_user.email}'", current_user, 'Forums')    
      @post.created_by_user.notes << UserNote.new(:category=>"Forum", :description=>"Removed all posts for spamming", :created_by_id=>current_user)
      TopicPost.delete_all_by_user(_sid, @post.created_by_user_id, current_user)
    else
      @post.created_by_user.user_notes << UserNote.new(:category=>"Forum", :description=>"Had <a href='#{@post.link}'>post</a> #{params[:delete]=='0' ? '' : 'un'}deleted", :created_by_id=>current_user.id)
    end

    render :js=>"done_delete(#{@post.id}, #{@post.is_visible});"
  end

  def edit_thread
    @thread = TopicThread.sys(_sid).where(:id=>params[:id]).first
    redirect_to "/forums" and return unless can?(:moderate, self) && @thread

    @thread.update_attributes(params[:topic_thread])
    respond_with_bip(@thread)
  end

  def fetch_raw
    @post = TopicPost.sys(_sid).where(:id=>params[:id]).first

    if can?(:moderate, self) || (@post.is_visible==1 && @post.topic_thread.is_visible==1 && @post.topic_thread.topic.is_visible==1 && level_okay(@post.topic_thread.topic.read_access_level))
      render :text=>@post.raw_body, :layout_o=>false
    else
      render :text=>"n/a", :layout_o=>false
    end
  end

  def edit_post
    @post = TopicPost.sys(_sid).where(:id=>params[:id]).first
    redirect_to "/forums" unless @post
    if can?(:moderate, self) 
      @post.edited(current_user)
      @post.moderation_comment ||= ''
      
      if @post.raw_body_changed?
#        if current_user.id != @post.created_by_user_id || @post.topic_thread.topic_posts.first.id != @post.id
          @post.moderation_comment += "Edited by #{current_user.email} at #{Time.now}<br/>" 
#        end
      end

      @post.moderation_comment += "Comment by #{current_user.email} at #{Time.now}: #{params[:comment]}<br/>" if params[:comment] && params[:comment].strip.length>0
      @post.raw_body = params[:body]
    elsif @post.created_by_user_id == current_user.id && @post.created_at > Time.now - (Preference.get_cached(_sid, "forum_post_edit_time") || "0").to_i.minutes
      @post.edited(current_user)
      @post.raw_body = params[:body] 
    else
      redirect_to "/forums" unless @post
    end

    @post.save

    render :json=>{:bod=>@post.body, :edits=>@post.edit_log}
  end

  private 
  def level_okay(minimum_level)
    return true if minimum_level == 0
    return false unless current_user
    return true if current_user.forum_level >= minimum_level
    return false
  end

  def load_forum_user_options
    @user_options = ForumUser.load(current_user)
  end

  def thread_order
    @thread_order = session[:thread_order] || @user_options.thread_order
    if params[:reverse] && params[:page]==nil
      @thread_order = reverse(@thread_order)  
      unless @user_options.default_user?
        @user_options.update_attributes(:thread_order=>@thread_order)
      end
    end

    session[:thread_order] = @thread_order
  end

  def post_order
    @post_order = session[:post_order] || @user_options.post_order
    if params[:reverse] && params[:page]==nil
      @post_order = reverse(@post_order)  
      unless @user_options.default_user?
        @user_options.update_attributes(:post_order=>@post_order)
      end
    end

    session[:post_order] = @post_order
  end

  def reverse(o)
    return o=="asc" ? "desc" : "asc"
  end

  def is_moderator
    @mod = can?(:moderate, :self)
    @show_edit_link = true
  end

  def get_layout(name, names = nil)
    ll = Rails.cache.fetch("layout-exists-forum-#{name}", :expires_in=>60.seconds) do
      l = nil
      names = [name] unless names
      names.each do |aname|
        if Layout.name_exists?(_sid, "forum-#{aname}")
          l = "forum-#{aname}"
          break
        end
      end
      if l==nil
        if Layout.name_exists?(_sid, "forum")
          l = "forum"
        end
      end 
      if l
        Layout.sys(_sid).where(:name=>l).first 
      else
        Layout.sys(_sid).order(:created_at).first
      end
    end
    ll
  end

  def post_info_params(post)
    return ""
  end

 def check_post_rate?
    last_post = TopicPost.sys(_sid).where(:created_by_user_id=>current_user.id).last
    if last_post
      if last_post.created_at > Time.now - 0.seconds
        logger.info "**** Posting too fast"
        redirect_to request.referer, :notice=>"You can't post again for at least 5 seconds" and return false
      end
    end

    return true
  end
  
  private 

  def load_topic(name)
    @topic = Topic.sys(_sid).where(:url=>name).includes([:topic_category, {:topic_threads=>[:topic]}]).first
  end
end

