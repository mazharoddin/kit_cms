module KitModulesHelper

  def kit_signin_form(options = {})
    account_sign_in_form(options)
  end

  def kit_page_list(options={})
    # category, template_snippet, limit = 5, order_by = "updated_at desc")
    pages = Page.sys(_sid)
    pages = pages.where("full_path like '#{options[:category]}%'") if options[:category]
    pages = pages.where(options[:where]) if options[:where]
    pages = pages.order(options[:order_by] || "updated_at desc").limit(options[:limit] || 5).all
    if options[:template_snippet]
      template = kit_snippet!(_sid, options[:template_snippet])
    else
      template = options[:template]
      template.gsub!("[", "<%").gsub!("]", "%>")
    end

    template ||= "No template"
    render :partial=>"pages/list", locals: { pages:pages, template:template.html_safe }
  end

  def kit_rss_feed(rss, opts = {})
    opts[:limit] = 5
    opts[:truncate_body] = 80
    opts[:html] = "strip"
    render :partial=>"utility/fetch_rss", :locals=>{:rss=>rss, :options=>opts}
  end

  def kit_page_terms_by_ids(ids)
    if @page
      PageTemplateTerm.where(:page_template_id=>@page.page_template_id).where(:system_id=>_sid).first.terms.where(:page_id=>@page.id).where("terms.page_template_term_id in (#{ids.join(',')})").pluck(:value)

    else
      nil
    end
  end

  def kit_page_terms(id) 
    kit_page_terms_by_ids([id])
  end

  def kit_term_options(term_id, page_template_id)
    pt = PageTemplate.sys(_sid).name_or_id(page_template_id).first
    term = pt.page_template_terms.name_or_id( term_id).first
    return "term '#{term_id}' not found" unless term

    r = {}
    term.form_field_type.options.split("|").each do |line|
      values = line.split('~')
      r[values[0]] = []
      for i in 1..(values.size-1)
        r[values[0]] << values[i]
      end
    end

    return r
  end 

  def kit_term_parent_list(term_id, page_template_id) # requires a block to which this will yield for each  parent term found, OR returns an array of arrays
    opts = kit_term_options(term_id, page_template_id)
    return "term '#{term_id}' not found" unless opts

    op = [] unless block_given?
    opts.each do |k,v|
      if block_given? 
        yield k 
      else
        op << [ k, v]
      end
    end
    return op unless block_given? 
  end

  def kit_term_child_list(term_id, page_template_id, parent_value)  # requires a block to which this will yield for each child term of the given parent
    opts = kit_term_options(term_id, page_template_id)
    return "term '#{term_id}' not found" unless opts

    child_opts = nil
    opts.each do |k,v|
      if k.urlise==parent_value
        child_opts = v
      end
    end

    return "parent '#{parent_value}' not found for term '#{term_id}'" unless child_opts
    op = [] unless block_given?
    child_opts.each do |v|
      if block_given?
        yield v
      else
        op << v
      end
    end

    return op unless block_given?
  end

  def kit_asset_src(id, size = :original, missing = "/images/not-found.png")
    src = Asset.asset_url(_sid, id, size)
    return src ? src : missing
  end

  def kit_asset(id, size = :original, options = {})
    src = Asset.asset_url(_sid, id, size)
    if src 
      return image_tag src, options
    else
      return "image '#{id}' not found"
    end
  end
  
  def kit_asset_tagged_src(tag, size = :original, missing = "/images/not-found.png")
    src = Asset.asset_tagged_url(_sid, tag, size)
    return src ? src : missing
  end

  def kit_asset_tagged(tag, size = :original, options = {})
    src = Asset.asset_tagged_url(_sid, tag, size)
    if src 
      return image_tag src, options
    else
      return "image '#{tag}' not found"
    end
  end


  def kit_forums_threads_im_on(count=5, options={})
    mod = can?(:moderate, ForumController)
   
    if current_user
      threads = TopicThread.im_on(current_user, count, mod)
      kit_render :partial=>"forum/thread_list",:locals=>{:threads=>threads, :options=>options} 
    else
     ""
    end 
  end

  def kit_forums_favourites(count=5, options={}) # also 'threads I'm watching'
    @user_options ||= ForumUser.load(current_user)
    mod = can?(:moderate, ForumController)
   
    if current_user
      threads = current_user.topic_threads
      kit_render :partial=>"forum/thread_list",:locals=>{:threads=>threads, :options=>options} 
    else
     ""
    end 
  end

  def kit_forums_recent_posts(count=5, options = {})
    mod = can?(:moderate, ForumController)

    threads = TopicThread.most_recent(current_user, count)

    kit_render :partial=>"forum/thread_list",:locals=>{:threads => threads, :options => options}
  end

  def kit_forums_recent_threads_from_topic_id(topic_id, count = 5, options = {})
    topic = Topic.sys(_sid).where(["topics.read_access_level <= ?", current_user ? current_user.forum_level : 0]).where(:is_visible=>1).where(:id=>topic_id).first
    return "" unless topic
    options[:show_topic] = false if options[:show_topic]==nil
    threads = topic.recent_threads(current_user, count)
    
    kit_render :partial=>"forum/thread_list",:locals=>{:threads => threads, :options => options}

  end

  def kit_forums_recent_threads_from_category_id(category_id, count = 5, options = {})
    category = TopicCategory.sys(_sid).where(["topic_category.read_access_level <= ?", current_user ? current_user.forum_level : 0]).where(:is_open=>1).where(:id=>category_id).first
    return "" unless category
    options[:show_topic] = false if options[:show_topic]==nil

    threads = category.recent_threads(current_user, count)
    
    kit_render :partial=>"forum/thread_list",:locals=>{:threads => threads, :options => options}

  end
  
  def kit_forums_topics
    topics = Topic.sys(_sid).where(["topics.read_access_level <= ?", current_user ? current_user.forum_level : 0]).where(:is_visible=>1).all

    kit_render :partial=>"forum/topic_list", :locals=>{:topics => topics, :category=>category, :show_headings=>false, :show_mod=>false, :show_meta=>false, :paginate=>false}
  end

  
  def kit_forums_topics_from_category_id(category_id)
    category = TopicCategory.sys(_sid).where(:id=>category_id).where(["read_access_level <= ?", current_user ? current_user.forum_level : 0]).where(:is_open=>1).first
    return "" unless category
    topics = category.topics.where(["topics.read_access_level <= ?", current_user ? current_user.forum_level : 0]).where(:is_visible=>1).all

    kit_render :partial=>"forum/topic_list", :locals=>{:topics => topics, :category=>category, :show_headings=>false, :show_mod=>false, :show_meta=>false, :paginate=>false}
  end

  def kit_calendar_entry_add(calendar_id, options = {})
    module_kit_calendar_entry_add(calendar_id, options)
  end

  def kit_calendar_entry(id, options = {})
    module_kit_calendar_entry(id, options)
  end

  def kit_calendar(calendar_id, options = {})
    module_kit_calendar(calendar_id, options)
  end

  def kit_menu(id) 
    html = Rails.cache.fetch(Menu.cache_key(_sid, id))

    return html if html

    if id.is_number?
      menu = Menu.sys(_sid).where(:id=>id).first 
    else
      menu = Menu.sys(_sid).where(:name=>id).first
    end

    html = (kit_render :partial=>"menu/render", :locals=>{:name=>id, :menu=>menu}).html_safe

    if menu && menu.can_cache==1
      Rails.cache.write(Menu.cache_key(_sid, id), html, :expires_in=>60.seconds, :race_condition_ttl=>5.seconds)
    end

    return html
  end

  def kit_random_snippet_line(id)
    lines = Snippet.parse_lines(id, _sid)
    return lines ? lines[rand(lines.size)].html_safe : "snippet '#{id}' not found"
  end

  def kit_dated_snippet_line(id)
    begin
      lines = Snippet.parse_lines(id, _sid)

      return "snippet '#{id}' not found" unless lines

      current = 'none'
      now = Time.now
      lines.each do |line|
        if line =~ /^(\d\d)\/(\d\d)\/(\d\d)\:(.*)$/
          date = DateTime.new((2000+$3.to_i),$2.to_i,$1.to_i)
          if date > now
            return current.html_safe
          else 
            current = $4
          end
        end
      end   
      return current.html_safe
    rescue Exception => e
      logger.debug("Error with kit_dated_snippet_line")
      logger.debug(e)
      logger.debug(e.backtrace.join("\r\n"))
      return "error"
    end
  end

  def kit_current_year
    Time.now.strftime("%Y")
  end  

  def kit_current_month(format = '%b')
    Time.now.strftime(format)
  end

  def kit_block_without_instance(id, options = {})
    @block = Block.cache_get(_sid, id)

    if @block
      render :inline=>@block.render_preview(options)
    else
      "[Block definition missing '#{id}']"
    end
  end

  def kit_block(id, version=0)
    if id.is_number?
      @instance = BlockInstance.where(:version=>version).sys(_sid).where(:id=>id).first
    else
      @instance = BlockInstance.where(:version=>version).sys(_sid).where(:instance_id=>id).first
    end
    if @instance
      begin
        (render :inline=>@instance.render).html_safe
      rescue Exception => e
        logger.debug("***** Block error: #{e.message}")
        e.message 
      end
    else
      "[Block instance missing '#{id}']"
    end
  end

  def kit_template_block(instance_id, block_id, defaults = {})
    kit_editable_block(instance_id, block_id, defaults)
  end

  def kit_editable_block(instance_id, block_id, defaults = {})
    block_instance = @page.block_instances.where(:instance_id=>instance_id).where(:version=>params[:version]||0).first

    unless block_instance
      block_instance = @page.generate_block_instance(instance_id, block_id, defaults, current_user.id)
    end

    block_with_options = block_instance.render
   
    block_rendered = render :inline=>block_with_options 

    r = %?
      <div class='mercury-region' data-type='snippetable' data-fieldid='#{instance_id}' data-field='#{instance_id}' id='#{instance_id}'><div class="mercury-snippet" data-snippet="#{instance_id}">#{block_rendered.html_safe}</div></div>
    
    ?.html_safe    
  end

  def kit_map(location, title="", height = 400, width = 400)
    kit_render :partial=>"utility/map", :locals=>{height: height, width: width, location: location, title:title}
  end

  def kit_snippet!(sid, id)
    b = Snippet.cache_get(sid, id)

    return nil unless b

    if b.has_code==1
      return  render(:inline=>b.body).html_safe
    else
      return b.body.html_safe
    end

  end

  def kit_snippet(id, default = nil, sid = nil)
    logger.debug "***&&&****&&&&*"
    b = Snippet.cache_get(sid ? sid : _sid, id)

    return default || "[Snippet missing '#{id}']" unless b

    if b.has_code==1
      return  render(:inline=>b.body).html_safe
    else
      return b.body.html_safe
    end
  end

  def kit_view(id)
    view = View.find_sys_id(_sid, id)
    view ? controller.get_view_content(view).html_safe : "[View missing '#{name}']"
  end

  def kit_users_email
    current_user ? current_user.email : ""
  end

  def kit_search
    kit_render :partial=>"pages/search_form", :locals=>{dashboard:false}
  end

  def kit_page_field(page_id, field_name, is_template = false)
    if page_id.is_number?
      page = Page.find_sys_id(_sid, page_id)
    else
      page = Page.sys(_sid).where(:full_path=>page_id).first
    end

    page ? field(field_name, is_template) : "[Page missing #{page_id}]"
  end 

  def kit_code(name)
    eval(name)
  end

  def kit_form(id, show_title = false, show_body = false, no_permissions="You need to sign in to see this")
    begin
    if id.is_number?
      form = Form.where(:id=>id).sys(_sid).first
    else
      form = Form.where(:url=>id).sys(_sid).first
    end

    if form
      if form.public_creatable || (current_user && form.user_creatable)
        kit_render(:partial=>"form/show", :locals=>{:form=>form, :show_title=>show_title, :show_body=>show_body, :submission=>nil}) 
      else
        no_permissions
      end
    else
      "[Form missing #{id}]"
    end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      Event.store("Form render error", request, current_user ? current_user.id : nil, e.message + "\n" + e.backtrace.join("\n"), "form #{form.id}") 
    end
  end

  def kit_form_edit_submission(id, submission_id, show_title = false, show_body = false, no_permissions="You need to sign in to see this")
    if id.is_number?
      form = Form.where(:id=>id).sys(_sid).first
    else
      form = Form.where(:url=>id).sys(_sid).first
    end

    sub = form.form_submissions.where(:id=>params[:edit]).first if form

    if sub && form
      if sub.can_edit?(current_user)
        kit_render(:partial=>"form/show", :locals=>{:form=>form, :show_title=>show_title, :show_body=>show_body, :submission=>sub}) 
      else
        no_permissions
      end
    else
      "[Form missing or submission missing #{id} - #{submission_id}]"
    end
  end

  def kit_gallery(id)
    gallery = Gallery.name_or_id(id).sys(_sid).includes(:assets).first
    gallery ? render(:partial=>"admin/gallery/view", :locals=>{:gallery=>gallery}) : "[Gallery missing #{id}]"
  end

  def kit_slideshow(id, options)
    gallery = Gallery.name_or_id(id).sys(_sid).first
    return "[gallery missing #{id}]" unless gallery

    assets = gallery.gallery_assets.order(:display_order).page(params[:page]).per(options[:per_page] || 10)
    render(:partial=>"admin/gallery/slideshow", :locals=>{:gallery=>gallery, :assets=>assets}) 
  end
  
  
end

