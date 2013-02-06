class Admin::DashboardController < AdminController
  layout  "cms"

  def user_comment
    comment = Comment.sys(_sid).where(:id=>params[:id]).first

    if comment
      if params[:delete]
        comment.destroy
        render :js=>"$('tr.comment_#{comment.id}').remove();"
      else
        comment.update_attributes(params[:comment])
        render :js=>"updated(#{comment.id}, #{comment.is_moderated}, #{comment.is_visible});"
      end
      return
    end

    render :js=>""
  end

  def user_comments
    if params.size==2
      params[:unmoderated] = "1"
      params[:visible] = "1"
      params[:invisible] = "1"
    end

    @comments = Comment.sys(_sid).order("created_at desc")
    conditions = []
    conditions << "is_moderated = -1"
    conditions << "is_moderated = 1" if params[:moderated]
    conditions << "is_moderated = 0" if params[:unmoderated]
    @comments = @comments.where(conditions.join(" or "))

    conditions = []
    conditions << "is_visible = -1"
    conditions << "is_visible = 1" if params[:visible]
    conditions << "is_visible = 0" if params[:invisible]
    @comments = @comments.where(conditions.join(" or "))

    @comments = @comments.page(params[:page]).per(params[:per] || 50)
  end

  def error
   raise Exception("Simulated error")
  end

  def plumb
    
  end

  def maintenance
    message = params[:message]
    if message.not_blank?
      Preference.set(_sid, "down_for_maintenance_message", message)
    else
      Preference.delete(_sid, "down_for_maintenance_message")
    end

    redirect_to "/admin/system", :notice=>"Message set"
  end

  def salesforce
    client = Databasedotcom::Client.new :client_id => "3MVG99qusVZJwhsnYBQ82sOeClHKBKrjEb5GTvhWfI_QwP72acY3t0TkXkjjFp7SadN3j7uywOrS5S8fAMYhX", :client_secret => "6488955455249765126"

    client.authenticate :username => "trial@dsc.net", :password => "sales1016c0S0Bc5EXrX2dRnRs8vb2bOm"

    @cats = client.materialize("Cat__c") 
  end

  def logfile
    filename = Rails.root.join('log', Rails.env + '.log')

    if params[:grep].not_blank?
      @output = `grep "#{params[:grep]}" #{filename}`
    else
      @lines = []
      File.open(filename) do |file|
        @file = file
        @file.extend(File::Tail)
        @file.backward((params[:lines] || "500").to_i )
        render "logfile"
      end
    end

  end

  def events
    raise Exception("permissions") unless can?(:dashboard, :super)

    if request.delete?
      Event.delete_all
    end
    @events = Event.order("created_at desc").page(params[:page]).per(50)
  end

  def event
    raise Exception("permissions") unless can?(:dashboard, :super)
    @event = Event.where(:id=>params[:id]).first
  end

  def index
  end

  def system
    raise Exception("permissions") unless can?(:dashboard, :super)

    @preferences = Preference.sys(_sid).where("user_id is null").order(:name)
    @preferences = @preferences.all
  end

  def build_system
    raise Exception("permissions") unless can?(:dashboard, :super)
  
    if request.post?  
      if params[:password] != params[:password_confirm]
        flash[:notice] = "Passwords don't match"
        return
      end

      if params[:password].length < 8
        flash[:notice] = "This password controls the whole system - it must be at least 8 characters"
        return
      end

      if params[:name].strip.length < 1
        flash[:notice] = "You must enter a system name"
        return
      end

      if params[:domain_name].strip.length < 1
        flash[:notice] = "You must enter a domain name"
        return
      end
    
      params[:full_name] ||= params[:name]

        system = System.new(:name=>params[:name])
        system.save
        SystemIdentifier.create(:system_id=>system.id, :ident_type=>"hostname", :ident_value=>params[:domain_name])
        user = User.create(:system_id=>system.id, :email=>params[:email], :password=>params[:password])
        role = Role.create(:system_id=>system.id, :name=>"SuperAdmin")
        user.roles << role
        Preference.get!(system.id, 'app_name', params[:name], nil)
        Preference.get!(system.id, 'site_name', params[:full_name], nil)
        Preference.get!(system.id, 'host', "http://#{params[:domain_name]}")
        redirect_to "/admin/integrity?system_id=#{system.id}"
    end
  end

  def integrity
    raise Exception("permissions") unless can?(:dashboard, :super)

    [ "js", "css", "other" ].each do |d|
      dir = File.join(Rails.root, "public", "kit", d)
      Dir::mkdir(dir) unless File.exists?(dir)
    end 
   
    @checks = []

    sid = params[:system_id]

    HtmlAsset.sys(sid).each do |ha|
      HtmlAsset.fetch(sid, ha.name, ha.file_type)
    end


    @system_id = sid
    prefs = {
      date_time_format: "%H:%M %d-%m-%y",
      app_name: System.find(sid).name.downcase,
      spam_points_to_ban_user: 5,
      error_layout: "application",
      notify: "tech@dsc.net"
    }

    prefs.each do |name, value|
      @checks << "Check preference '#{name}' exists and creating it if not"
      Preference.get!(sid, name.to_s, value, nil)
    end

    if Topic.sys(sid).count == 0 
      @checks << warning_message('There are no forum topics')
    end

    Topic.sys(sid).find_each do |topic|
      @checks << "Setting thread count and last post on topic '#{topic.name}'"
      topic.thread_count = topic.topic_threads.count
      last_post = TopicPost.joins(:topic_thread).order("topic_posts.id desc").where("topic_threads.topic_id = #{topic.id}").limit(1).first
      topic.last_post_at = last_post.updated_at rescue nil
      topic.save
    end

    if params[:forums]
      @checks << "Setting post count and last post info on threads"

      Topic.find_each do |topic|
        topic.last_thread_id = nil
        topic.post_count = 0
        topic.last_post_at = nil
        topic.post_count = 0
        topic.save
      end

      last_post_per_topic = {}

      TopicThread.find_each do |thread|
        posts = thread.topic_posts.order("topic_posts.created_at")
        n = 0

        posts.reverse.each do |post|
          if post.is_visible==1
            n += 1 
            post.post_number = n
          else
            post.post_number = 0
          end
          begin
          post.save
          rescue 
          end
        end 
        last_post = posts.first
        first_post = posts.last
        thread.post_count = n 
        thread.last_post_at = last_post.created_at
        thread.last_post_by_user_id = last_post.created_by_user_id
        thread.created_by_user_display_name = thread.created_by_user.display_name rescue ''
        thread.last_post_by_user_display_name = last_post.created_by_user.display_name

        thread.first_post_id = first_post.id
        thread.save
        thread.topic.thread_count += 1 rescue 1
        thread.topic.post_count += n rescue 1
          thread.topic.last_thread_id = thread.id
        if last_post_per_topic[thread.topic_id]==nil || last_post.id > last_post_per_topic[thread.topic_id]
          last_post_per_topic[thread.topic_id] = last_post.id
        end
        thread.topic.save
      end

      last_post_per_topic.each do |topic_id, last_post_id|
        topic = Topic.find(topic_id)
        next unless topic
        topic.last_post_id = last_post_id
        topic.last_post_at = TopicPost.find(last_post_id).created_at
        topic.save
      end


      @checks << "Forum votes"
      post_scores = {}
      user_scores = {}
      user_votes = {}
      TopicPostVote.find_each do |topic_post_vote|
        post_scores[topic_post_vote.topic_post_id] ||= 0
        post_scores[topic_post_vote.topic_post_id] += topic_post_vote.score
        user_scores[topic_post_vote.topic_post.created_by_user_id] ||= 0
        user_scores[topic_post_vote.topic_post.created_by_user_id] += topic_post_vote.score
        user_votes[topic_post_vote.topic_post.created_by_user_id] ||= 0
        user_votes[topic_post_vote.topic_post.created_by_user_id] += 1
      end 
      post_scores.each do |k,v|
        TopicPost.connection.execute("update topic_posts set score = #{v} where id = #{k}")
      end
      user_scores.each do |k,v|
        User.connection.execute("update users set forum_points = #{v}, forum_votes = #{user_votes[k]} where id = #{k}")
      end
    end

    @checks << "Checking statuses"
    i = 0
    ["Editing", "For review", "Ready for publication", "Published", "Withdrawn", "Stub"].each do |status|
      i += 1
      if Status.sys(sid).where(:name=>status).count==0
        @checks << "Creating '#{status}'"
        Status.create(:name=>status, :order_by=>i, :is_published=>(status=="Published"), :is_default=>(status=='Editing'), :is_stub=>(status=='Stub'), :system_id=>sid)
      end
    end
    @checks << "Check editor-styles block exists and creating if not"
    Block.ensure(sid, "editor-styles", "<div class='mercury-select-options'><div class='red' data-class='red'>Red Text</div></div>")
    @checks << "Check editor-blocks block exists and creating if not"
    Block.ensure(sid, "editor-blocks", "<div class='mercury-select-options'><h1 data-tag='h1'>Heading 1 <span>&lt;&gt;</span></h1><div data-tag='p'>Paragraph <span>&lt;&gt;</span></div>")

    @home_page = Pagebase.sys(sid).where(:id=>Preference.getCached(sid, "home_page")).first rescue nil

    @checks << "Check default layout"
    if Layout.sys(sid).count < 1
      @checks << "Creating default layout"
      Layout.create_default(sid, current_user.id)
    end
    
    @checks << "Check default stylesheet"
    if HtmlAsset.sys(sid).count < 1
      @checks << "Creating default stylesheet"
      HtmlAsset.create_default(sid, current_user.id, 'css')
    end
   
    @checks << "Check default page template"
    if PageTemplate.sys(sid).count < 1
      @checks << "Creating default page template"
      PageTemplate.create_default(sid, current_user.id)
    else
      if PageTemplate.sys(sid).where(:is_default=>1).count<1
        @checks << "Making first template the default"
        PageTemplate.order(:created_at).first.update_attributes(:is_default=>1)
      end
    end
   
     
    @checks << "Check system identifier"
    if SystemIdentifier.sys(sid).count < 1
      @checks << error_message("No system identifier exists - nobody will be able to access this system")
    end

    @checks << "Check default category"
    if Category.sys(sid).count < 1
      @checks << "Creating default category"
      Category.create_default(sid)
    end

    [ "Moderator", "Editor", "Designer" ].each do |role|
      @checks << "Check role #{role}"
      if Role.sys(sid).where(:name=>role).count==0
        @checks << "Creating role #{role}"
        Role.create(:system_id=>sid, :name=>role)
      end
    end

  end

  def sysadmin
  end

  def update_preference
    raise Exception("permissions") unless can?(:dashboard, :super)

    Preference.set(_sid, params[:attr], params[:preference][:value], nil)
      
    respond_with_bip(Preference.where(:name=>params[:attr]).sys(_sid).where("user_id is null").first)
  end



  def system_settings
    raise Exception("permissions") unless can?(:dashboard, :super)
    
    if ["eu_cookies", "mobile_dif_by_default"].include?(params[:attr])
      Preference.set(_sid, params[:attr], params[:value], nil)
    end

    redirect_to "/admin/system"
  end

  def recent_pages
    render :partial=>"recent_pages"
  end

  def recent_activity
    render :partial=>"recent_activity"
  end
  
  @@to_search = [ "Page", "User", "Help", "Category", "Asset", "TopicPost", "TopicThread", "FormSubmission"]

  def reindex
    @@to_search.each do |model|
      modelk = Kernel.const_get(model)

      modelk.index.delete rescue nil
      modelk.create_elasticsearch_index

      if params[:slow]
        modelk.find_each do |record|
          logger.info "Importing #{model} #{record.id}"
          modelk.index.store  record
        end
      else
        modelk.import :per_page=>1000
      end
    end 

    flash[:notice] = "Reindex complete"
    redirect_to "/db"
  end
    
  def search
    search_for = params[:for]
    indexes = []
    search_fields = []

    @@to_search.each do |model|
      if params["include_#{model.pluralize.downcase}".to_sym]
        indexes << "kit_#{app_name.downcase}_" + model.tableize
        KitIndexed.indexed_columns(model).collect { |ic| 
          next if ic[:include_in_all]==false
          next if ic[:index]==:not_analyzed
          search_fields << ic[:name] 
        }
      end
    end
    
    if params[:include_pages]  
      search_fields << "old_content" if params[:include_old]
      search_fields << "draft_content" if params[:include_draft]
      search_fields << "autosave_content" if params[:include_autosave]
    end
    
    system_id = _sid

    search = Tire.search indexes.join(',') do
      query do
        string search_for, :fields=>search_fields.uniq
      end
      filter :term, :system_id=>system_id

    end
    logger.info "SEARCH: #{indexes.join(',')} #{search.to_json}"

    @results = search.results
    logger.debug "RESULTS: #{@results.size}"
    @to_search = @@to_search
  end

  def activity
    @activity = Activity

    if params[:for]
      @activity = @activity.where(Activity.arel_table[:name].matches("%#{params[:for]}%").or(Activity.arel_table[:name].matches("%#{params[:for]}%"))).sys(_sid)
    else
    @activity = @activity.includes(:user)
    end
    @activity = @activity.where(["category = ?", params[:cat]]) if params[:cat]
    @activity = @activity.sys(_sid)
    @activity = @activity.order("created_at desc").page(params[:page]).per(100)
    

    if request.xhr?
      render :partial=>"activity_list"
    else
      render "activity", :layout=>"cms"
    end
  end

  def help 
    if params[:search]
      search_for = params[:search]

      search = Tire.search "kit_#{app_name}_helps" do
        query do
          string search_for, :fields=>["name", "body", "path"]
        end
      end
      @helps = search.results
      render "helps"
      return
    else      
     params[:url] = "index" unless params[:url]
     @help = Help.where(:path=>params[:url]).first
     if @help==nil
       render "help_not_found"
       return
     end
    end 
  end

  def error_message(s)
    "<span class='check_error'>#{s}</span>".html_safe
  end

  def warning_message(s)
    "<span class='check_warning'>#{s}</span>".html_safe
  end

end
