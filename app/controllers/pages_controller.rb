class PagesController < KitController

  before_filter :load_page, :except=>[:search, :cookie_text, :unique, :index, :new, :create, :stub, :zoom, :terms, :editor_trial]
  before_filter :can_use, :except=>[:show, :search, :cookie_text, :editor_trial, :save, :redir]

  layout "layouts/cms"

  def copy
    @original = @page

    @page = Page.new
    @page.copy_of = @original.id
    @page.system_id = _sid
    @page.status = Status.default_status(_sid)
    @page.page_template = PageTemplate.find(@original.page_template_id)
    @page.category_id = @original.category_id
    @page.title = @original.title
    @page.meta_description = @original.meta_description
    @page.meta_keywords = @original.meta_keywords
    @page.header = @original.header
    @page.tags = @original.tags

    render "new", :layout=>"cms"

  end

  def browser_dif
    return true
  end

  def cookie_text
    render :layout=>false 
  end

  def menu
    menu = Menu.sys(_sid).where(:id=>params[:menu_id]).first
    menu.add_page(@page, @page.title, params[:parent_id])
    redirect_to @page.link('info')
  end

  def possible_terms
    data = {}

    data[:query] = params[:query]

    terms = Term.arel_table
    data[:suggestions] = Term.where(:page_template_term_id=>params[:page_template_term_id]).select("distinct terms.value").sys(_sid).where(terms[:value].matches("%#{params[:query]}%")).map { |t| t.value }
    data[:data] = data[:suggestions]

    render :json=>data
  end

  def unique
    category = Category.find_sys_id(_sid, params[:cat_id])
    valid = false
    if category
      if category.pages.where(:name=>params[:name]).count==0
        valid = true 
      end
    end

    render :js=>"page_name_valid(#{valid});"
  end

  def show_block_content
    @block_instance = BlockInstance.find_sys_id(_sid, params[:content_id])

    @block_contents = BlockInstance.where(:page_id=>@block_instance.page_id).where(:block_id=>@block_instance.block_id).where(:instance_id=>@block_instance.instance_id).where(:version=>@block_instance.version).order(:field_name).all

    render "block_content", :layout=>"minimal"
  end

  def show_content
    @page_content = PageContent.find_sys_id(_sid, params[:content_id])

    render "content", :layout=>"minimal"
  end

  def content_edit
    @page_content = PageContent.find_sys_id(_sid, params[:content_id])
  end

  def content_update
    @page_content = PageContent.find_sys_id(_sid, params[:content_id])
    @page_content.value = params[:page_content][:value]
    @page_content.save
    redirect_to "/page/#{@page.id}/contents" 
  end

  def contents
    params[:mode] = 'current' unless params[:mode]
  end

  def search
    if params[:search]
      search_fields = []
      indexes = []
      system_id = _sid
      search_size = (params[:per] || "5").to_i
      the_page = (params[:page] || "1").to_i 

      [ "Page" ].each do |model|
        indexes << "kit_#{app_name.downcase}_#{model.downcase.pluralize}"
        KitIndexed.indexed_columns(model).collect { |c|
          search_fields << c[:name] if c[:user]
        }
      end

      search_term = params[:search]   
      search = Tire.search indexes.join(',') do 
        query do
          string search_term, :fields=>search_fields.uniq
        end
        filter :term, :status => "published"
        filter :term, :is_deleted => 0
        from (the_page-1)*search_size 
        size search_size
        filter :term, :system_id=>system_id
      end
      @results = search.results
    else
      @results = nil
    end

    @searched_for = params[:search]

    @show_edit_link = user_can_edit = can?(:use, self)
    kit_render "pages/search", :layout=>Preference.getCached(_sid, "layout_search") || "application"
  end

  def auto_save_delete
    if params[:what] == 'blocks'
      BlockInstance.delete_all("version = -2 and page_id = #{@page.id}")
    end

    if params[:what] == 'contents'
      @page.clear_auto_save  
    end

    redirect_to "/page/#{@page.id}/info"
  end


  def save
    raise "cannot save (permissions)" unless @page.id == session[:trial_page_id]  || can_use
    fields = ActiveSupport::JSON.decode(params[:content])
    auto_save = params[:auto]=='1'

    version = auto_save ? -2 : (@page.draft ? -1 : 0) 

    fields.each do |field,data|
      field_name = field
      field_index = 1
      new_value = data["value"]

      field_name = data["data"]["fieldid"]
      @page.update_field(field_name, new_value,  current_user, field_name.titleize, version)
    end

    # if this is a real (non auto) save, zap any auto saves
    @page.clear_auto_save if auto_save==false

    PageEdit.delete_all(["page_id = ? and user_id = ?", @page.id, current_user ? current_user.id : 0]) 
    Activity.add(_sid, "Edit page <a href='#{@page.full_path}'>#{@page.full_path}</a>", current_user ? current_user.id : 0, "Pages", '') if auto_save==false

    unless auto_save
      @page.updated_at = Time.now 
      @page.save
      @page.update_index 
    end

    render :js=>""
  end

  def add_note
    comment = PageComment.new(:user=>current_user, :body=>params[:body])
    comment.save
    @page.page_comments << comment
    Activity.add(_sid, "Add comment to page <a href='#{@page.full_path}'>#{@page.full_path}</a>", current_user.id, "Pages", comment.body)    
    if params[:mercury]
      render :partial=>"mercury-notes"
    else
      render "pages/comment.js.erb", :layout=>false
    end
  end

  def notes
    render "notes", :layout=>false  
  end

  def zoom
    render "mock"
  end

  def index
    if params[:cat_id]
      @category = Category.where(:id=>params[:cat_id]).first
    else
      @category = Category.root(_sid)
    end

    if params[:status_id]
      @status = Status.find_sys_id(_sid, params[:status_id])   
      @mode = @status.name   
      @pages = Page.sys(_sid).where(:status_id=>params[:status_id]).order("updated_at desc").page(params[:page]).per(10)
    elsif params[:fav] && current_user
      fpc = current_user.favourites_pages_comma
      @pages = Page.sys(_sid).where("id in (#{fpc})").order("updated_at desc").page(params[:page]).per(10) if fpc.length>0
      @mode = "Favourites"
    else
      @pages = Page.sys(_sid).order("updated_at desc").page(params[:page])
      @mode = "Recent"
    end
    render "index" 
  end

  def editor_trial
    if session[:trial_page_id]==nil || params[:force]
      source_id = Preference.get_cached(_sid, "edit_trial_source_page_id")
      raise "can't generate a trial page without setting 'edit_trial_source_page_id' preference" unless source_id

      source_page = Page.sys(_sid).where(:id=>source_id).first
      trial_category_id = Preference.get_cached(_sid, "edit_trial_category")
      raise "can't generate a trial page without setting 'edit_trial_category' preference" unless trial_category_id
      trial_category = Category.sys(_sid).where(:id=>trial_category_id).first

      source_page.name = "trial-#{rand(1000000)}"

      trial_page_id = source_page.copy_to(trial_category)
      raise "couldn't create trial page" unless trial_page_id
      session[:trial_page_id] = trial_page_id
      trial_page = Page.find(trial_page_id)
      trial_page.publish(0)
    else
      trial_page_id = session[:trial_page_id]
      trial_page = Page.find(trial_page_id)
    end

    redirect_to trial_page.link('show', true)
  end

  def show 
    return unless check_category_permissions
    user_can_edit = can?(:use, self)

    @page.editable = (params[:edit]!=nil) && (user_can_edit || @page.id==session[:trial_page_id]) && !@page.locked?

    if @page.editable
      if @page.is_home_page? && request.post? # if the user posts to /?edit=1 they'll end up here, despite really wanting to do a save, so:
        save
        return
      end
      if session[:runaway_check]
        logger.debug "Doing runaway check"
        if session[:runaway_check] > Time.now - 15.seconds
          redirect_to "/page/#{@page.id}?edit=1&mercury_frame=1#{'&draft=1' if @page.draft}"
          session[:runaway_check] = nil
          return
        end
      end

      if !params[:mercury_frame]
        session[:runaway_check] = Time.now
        render :text=>"", :layout=>"mercury-editor"
        return
      end
    end

    session[:runaway_check] = nil
    page_name = params[:id]

    if (@page==nil || @page.is_deleted==1 || !@page.is_published?) && !@page.editable && cannot?(:use, self)
      session[:error_message] = "Page not found"
      render "/error/404", :status=>404, :layout=>@page ? @page.dif_template(use_mobile?).layout.path : false
      return
    end 

    if (@page==nil && can?(:use, self))
      flash[:notice] = "Page not found"
      redirect_to "/pages"
      return
    end

    @show_edit_link = true if user_can_edit && !@page.editable
    render_page(@page) # in kit_controller base class
  end

  def redir
    redirect_to @page.full_path + (params[:draft] ? "?draft=1" : "")
    return
  end

  def favourite
    if request.post?
      current_user.pages << @page
      notice = "Added to Favourites"
    elsif request.delete?
      current_user.pages.delete(@page)
      notice = "Removed from Favourites"
    end

    redirect_to "/page/#{@page.id}/info", :notice=>notice
  end

  def destroy
    if @page.is_stub?
      Page.destroy(params[:id])
    else
      if params[:destroy] 
        Page.destroy(params[:id])
        flash[:notice] = "Page destroyed"
        redirect_to "/pages" and return
      else
        @page.update_attributes(:is_deleted=>1)
      end
    end
    flash[:notice] = "Page #{'Stub ' if @page.is_stub?}deleted"
    unless request.xhr?
      redirect_to request.referer  # "/page/#{@page.id}/info"
    else
      render :json=>{:message=>flash[:notice]}
    end
  end

  def undelete
    @page.update_attributes(:is_deleted=>0)
    flash[:notice] = "Page undeleted"
    unless request.xhr?
      redirect_to request.referer  # "/page/#{@page.id}/info"
    else
      render :json=>{:message=>flash[:notice]}
    end
  end

  def stub
    @page = Page.new
    @page.system_id = _sid
    @page.title = params[:name]
    @page.name = @page.name_from_title
    @page.status = Status.stub_status(_sid)
    @page.category_id = params[:cat_id]
    @page.page_template_id = nil
    @page.created_by = current_user.id
    if @page.save
      render :json=>{:id => @page.id, :name => @page.name, :okay=>true, :message=>"Page Stub Created"}
    else
      render :json=>{:okay=>false, :message=>"Could not save: A page with that name already exists"}
    end
  end

  def new
    @page = Page.new
    @page.system_id = _sid
    @page.status = Status.default_status(_sid)
    @page.page_template_id = PageTemplate.sys(_sid).where(:is_default=>1).first.id rescue Pagetemplate.first.id
    @page.category_id = params[:cat_id]

    render "new", :layout=>"cms"
  end

  def create
    @page = Page.new(params[:page])
    @page.system_id = _sid
    @page.mobile_dif = Preference.getCached(_sid, 'mobile_dif_by_default')!='false' ? 1 : 0
    @page.created_by = current_user.id
    @original = nil
    if @page.save
      if @page.copy_of
        @original = Page.sys(_sid).where(:id=>@page.copy_of).first
        @page.copy_content_from(@original)
      end
      Activity.add(_sid,"Created page '#{@page.name}' as <a href='#{@page.full_path}'>#{@page.full_path}</a>", current_user.id, 'Pages')
      @page.generate_block_instances(current_user.id) unless @original

      redirect_to @page.link("show", true)
      return
    else
      @page.copy_of = params[:page][:copy_of]
      if @page.copy_of
        @page.page_template_id = Page.sys(_sid).where(:id=>@page.copy_of).first.page_template_id
      else
        @page.page_template_id = params[:page][:page_template_id]
      end
      render "new"
    end
  end

  def edit
  end

  def make_home
    @page.make_home_page!
    Activity.add(_sid, "Page <a href='#{@page.full_path}'>#{@page.full_path}</a> made to be home page", current_user.id, "Pages", '') 
    redirect_to "/page/#{@page.id}/info" 
  end

  def make_draft
    @page.make_draft(current_user.id)
    flash[:notice] = "Draft created"
    redirect_to "/page/#{@page.id}/info"
    return
  end    

  def destroy_draft
    @page.destroy_draft(current_user.id)
    flash[:notice] = "Draft deleted"
    redirect_to "/page/#{@page.id}/info"
  end

  def publish_draft
    @page.draft = true
    @page.publish(current_user.id)
    flash[:notice] = "Draft published"
    Activity.add(_sid, "Draft page <a href='#{@page.full_path}'>#{@page.full_path}</a> published", current_user.id, "Pages", '') 
    redirect_to "/page/#{@page.id}/info"
  end

  def terms
    @page = Page.find_sys_id(_sid, params[:id])
    @new_terms = []

    page_template_terms = @page.page_template.page_template_terms
    if request.post? 
      params.each do |p,v|
        if ptt = @page.page_template.term(p)
          new_terms = @page.add_term(ptt, v)
          @new_terms += new_terms if new_terms
        end
      end
      render "add_term", :format=>:js
      return
    end
    if request.delete?
      @old_term = Term.find_sys_id(_sid, params[:term_id])
      Term.delete_all("id = #{params[:term_id]} and system_id = #{_sid}")
      render "remove_term", :format=>:js
    end
    @term = Term.new
    @terms = @page.terms
  end

  def info    
    if params[:sitemap] && request.post?
      @page.skip_history
      @page.update_attributes(:in_sitemap=>params[:sitemap])
      Activity.add(_sid, "Page <a href='#{@page.full_path}'>#{@page.full_path}</a> #{params[:sitemap]=='1' ? 'added to' : 'removed from'} sitemap", current_user.id, "Pages", '') 
      flash[:notice] = "Sitemap updated"
      redirect_to "/page/#{@page.id}/info"
    end

    if params[:locked]!=nil &&  request.post?
      @page.locked = params[:locked]=='true' ? 1 : 0
      Activity.add(_sid, "Page <a href='#{@page.full_path}'>#{@page.full_path}</a> #{@page.locked ? 'locked' : 'unlocked'}", current_user.id, "Pages", '') 
      @page.save
    end

    if params[:anonymous_comments] && request.post?
      @page.allow_anonymous_comments = params[:anonymous_comments]=='true' ? 1 : 0
      Activity.add(_sid, "Set anonymous comments #{@page.allow_anonymous_comments? ? 'on' : 'off'} for page <a href='#{@page.full_path}'>#{@page.full_path}</a>", current_user.id, "Pages", '') 
      @page.save
    end

    if params[:user_comments] && request.post?
      @page.allow_user_comments = params[:user_comments]=='true' ? 1 : 0
      Activity.add(_sid, "Set user comments #{@page.allow_user_comments? ? 'on' : 'off'} for page <a href='#{@page.full_path}'>#{@page.full_path}</a>", current_user.id, "Pages", '') 
      @page.save
    end

    if params[:remove_term] && request.post?
      Term.delete_all("id = #{params[:remove_term]} and system_id = #{_sid}")
    end

    if params[:mobile_dif] && request.post?
      @page.mobile_dif = params[:mobile_dif]
      @page.save
    end

    if params[:publish]=="1" && request.post?
      @page.publish(current_user.id)
      Activity.add(_sid, "Page <a href='#{@page.full_path}'>#{@page.full_path}</a> published", current_user.id, "Pages", '') 
      flash[:notice] = "Page published"
      redirect_to "/page/#{@page.id}/info"
    end

    editors = @page.page_edits.includes(:user)
    @being_edited_by = editors.map { |e| e.user.email }    
  end


  def notification
    mode = params[:mode]

    if mode=='open'
      ActiveRecord::Base.connection.execute("update page_edits set updated_at = now() where page_id = #{params[:id]} and user_id = #{current_user.id}")
      render :js=>"notification_done('#{mode}');", :layout=>false
    elsif mode=='edit'
      two_mins_ago = Time.now - 2.minutes
      PageEdit.delete_all(["page_id = ? and (updated_at < ? or user_id = ?)", params[:id], two_mins_ago, current_user.id])

      edits = PageEdit.select("distinct page_id, user_id").where(:page_id=>params[:id]).where("user_id <> #{current_user.id}").includes(:user).all

      ActiveRecord::Base.connection.execute("insert into page_edits (page_id, user_id, created_at, updated_at) values (#{params[:id]}, #{current_user.id}, now(), now())")

      being_edited_by = edits.map { |e| e.user.email }    

      if being_edited_by.size>0
        render :js => "being_edited_by('#{being_edited_by.join(',')}')"
      else
        render :js => "notification_done('#{mode}');"
      end
    elsif mode=='finished'
      PageEdit.delete_all(["page_id = ? and user_id = ?", params[:id], current_user.id]) 
      render :js=>"notification_done('#{mode}');"
    elsif mode=='force'
      PageEdit.delete_all(["page_id = ?", params[:id]]) 
      render :js=>"notification_done('#{mode}');"
    elsif mode=='delete'
      PageEdit.delete_all(["page_id = ?", params[:id]]) 
      p = Page.find_sys_id(_sid, params[:id])
      redirect_to p.link('info')
    else
      logger.info("Unknown Mode");
      render :text=>"", :layout=>false
    end
  end


  def update
    old_path = @page.full_path
    if @page_params[:status_id]
      is_published = Status.find_sys_id(_sid, @page_params[:status_id])
      if is_published==0 && self.published_at!=nil
        self.published_at = nil
      end
      if is_published==1 && self.published_at==nil
        self.published_at = Time.now
      end
    end
    @page.updated_by = current_user.id

    if @page.update_attributes(@page_params)
      if params[:redirection] && @page.full_path != old_path
        Mapping.create(:system_id=>_sid, :source_url=>old_path, :target_url=>@page.full_path, :user_id=>current_user.id, :status_code=>"301", :is_active=>true, :params_url=>"")
      end
      redirect_to "/page/#{@page.id}/info"
      return
    else
      render "edit", :layout=>"cms"
    end
  end

  def load_page
    if params[:url]
      url = params[:url] || ""
      url += ".#{params[:format]}" if params[:format]

      use_experiments = Preference.get_cached(_sid, "feature_experiments")=='true'
      self.requested_url = url
      if use_experiments && experiment = Experiment.alternative(_sid, url)
        exp_option = cookies["experiment_#{experiment.id}".to_sym]  
        url, selected_option  = experiment.invoke(exp_option)
        cookies["experiment_#{experiment.id}".to_sym] = {:value=>selected_option, :expires=>Time.now+30.minute}
        @canonical_tag = "/" + self.requested_url
      end
      @page = Pagebase.sys(_sid).where(full_path:"/"+url).first
      if @page==nil && url =~ /^page\/(\d+)$/
        @page = Pagebase.sys(_sid).where(id: $1).first
      end
      if @page==nil && url
        @page = Pagebase.sys(_sid).where(full_path:"/#{url}/index").first
      end
    else
      params[:id] ||= Preference.getCached(_sid, "home_page") 
      @page= Pagebase.sys(_sid).where(id: params[:id]).first
    end

    if @page
      @page_params = params[:page]
      @page.draft = params[:draft]=="1" if @page
    else
      @form = Form.sys(_sid).where(:url=>"/#{params[:url]}").includes({:form_field_groups=>{:form_fields=>:form_field_type}}).first

      if @form
        show_form(@form) and return
      end

      mapping = Mapping.sys(_sid).where(:source_url=>"/#{params[:url]}.#{params[:format]}").where(:is_active=>1).first
      mapping ||= Mapping.sys(_sid).where(:source_url=>"/#{params[:url]}").where(:is_active=>1).first
      mapping ||=  Mapping.sys(_sid).where(["? like source_url", "/#{params[:url]}"]).where(:is_active=>1).first

      if mapping
        if mapping.is_asset?
          # /file/251/0bec69beb/robots.txt
          target_params = mapping.target_url.split('/')
          logger.debug "------ #{target_params[2]}"
          get_asset(target_params[2], target_params[3]) and return 
        end          
        url = "/#{params[:url]}".split(/\//)
        if mapping.params_url
          surl = mapping.params_url.split(/\//)
          for i in 0..(surl.size-1) do
            if surl[i] =~ /\:(.+)/
              logger.debug "FOUND NAME: #{$1}"
              logger.debug "** #{url[i]}"
              params[$1] = url[i]
            end
          end
        end

        if mapping.is_page?
          @page = Pagebase.where(:full_path=>mapping.target_url).first
        else
          redirect_to eval('"' + mapping.target_url + '"'), :status=>mapping.status_code || 301
        end
      else
        not_found  
      end      
    end
  end

  private 

  def check_category_permissions
    return true if @page.category.user_can_read?(current_user)

    if current_user
      flash[:debug_error_message] = "No read permission for #{current_user ? current_user.email : 'anon'} to category: #{@page.category.id}"
      no_read
    else
      session[:return_to] = request.fullpath
      redirect_to "/users/sign_in"
      return false
    end
  end

end
