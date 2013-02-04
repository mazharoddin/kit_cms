class KitController <  ActionController::Base
  include DomainController
  helper :all
  helper_method :stylesheets
  before_filter :set_requested_url, :except=>[:not_found_404]
  before_filter :set_system, :except=>[:not_found_404]
  before_filter :offline, :except=>[:not_found_404, :down_for_maintenance]
  before_filter :kit_session, :except=>[:not_found_404]
  after_filter :kit_session_end, :except=>[:not_found_404]
  append_view_path Layout.resolver

  after_filter :check_and_record_goal, :except=>[:not_found_404]


  attr_accessor :layout_name_being_used
  attr_accessor :template_being_used
  attr_accessor :requested_url
  
  attr_accessor :is_image_request
  attr_accessor :kit_request

  def set_requested_url
    self.is_image_request = false 
    self.requested_url = request.fullpath

    if self.requested_url =~ /\.(?:jpg|png|gif|jpeg)$/i
      self.is_image_request = true
   end
  end

  def check_and_record_goal
    return if self.is_image_request
      use_experiments = Preference.get_cached(_sid, "feature_experiments")=='true'
      if use_experiments
        started = cookies[:started] || Time.now
        cookies[:started] = {:value=>started, :expires=>Time.now+30.minutes}

        if Goal.has_goals?(_sid)
         Goal.record_request(_sid, self.requested_url, cookies, current_user, started, session) 
        end
      end
  end

  def session_id
    session[:session_id]
  end

  def offline
    return if (current_user && current_user.admin?) || params[:overrride]

    message = Preference.get_cached(_sid, "down_for_maintenance_message")
    if message
      render :text=>Preference.get_cached(_sid, "down_for_maintenance_message"), :layout=>false, :status=>503
      return false
    end
  end

  def kit_session
    return if self.is_image_request
    return if self.is_a?(AdminController) || (self.is_a?(PagesController) && params[:action]!="show") || self.is_a?(CategoryController) || self.is_a?(ImagesController)
    ks = KitSession.sys(_sid).where(:session_id=>session_id).first

    unless ks
      ks = KitSession.create(:session_id=>session_id, :user_id=>0, :first_request=>Time.now, :page_views=>0, :system_id=>_sid)
    end

    kr = KitRequest.new
    kr.kit_session_id = ks.id
    kr.ip = request.remote_ip
    kr.url = request.fullpath
    kr.referer = request.referer
    kr.save

    ks.update_attributes(:last_request=>Time.now, :page_views => ks.page_views + 1, :user_id=>current_user ? current_user.id : 0)
  end

  def stylesheets
    if @page
      return (@page.page_template.layout.stylesheets + "," + @page.page_template.stylesheets).split(',').uniq
    elsif @form
      return @form.include_stylesheets
    else
      layout = kit_layout_in_use
      if layout
        return layout.stylesheets.split(',').uniq
      else
        return ["application"]
      end
    end
  end


  def kit_layout_in_use
    l = nil

    if self.layout_name_being_used # this gets set if kit_render is being used
      l = Layout.sys(_sid).where(:name=>self.layout_name_being_used).first
    else 
      l = @page.layout if @page
    end

    return l
  end

  def kit_session_end
    return if self.is_image_request
    response["handler"] = "Kit/#{params[:controller]}/#{params[:action]}"
  end

  alias :super_render :render

  def render(name = params[:action], options = {})
    if Preference.get_cached(_sid, 'dont_use_overridable_templates')=='true' || (params[:controller] && params[:controller].starts_with?('admin/'))
      super_render(name, options)
    else
      kit_render(name, options)
    end
  end

  def kit_render(name, options = {})
    if options[:partial]
      name = options[:partial]
    end

    custom_template = PageTemplate.get_custom_template(_sid, name, request)
    if custom_template
      @content = render_to_string name, :layout=>false
      options[:type] = custom_template.template_type || 'erb'
      options[:inline] = custom_template.body
      options[:layout] = custom_template.layout.path
      self.template_being_used = custom_template
      self.layout_name_being_used = custom_template.layout.name
      super_render options
    else
      self.layout_name_being_used = options[:layout]
      super_render name, options
    end
  end

  def mobile_template(l)
    return Rails.cache.fetch("_mobile_template_#{l}", :expires_in=>1.minute) do 
      parts = l.split('/')
      fn = ''
      for i in 0..parts.size-1
        fn += '/' unless parts.size==1
        fn += 'mobile-' if i==parts.size-1
        fn += parts[i]
      end

      sep = fn[0]=='/' ? '' : '/'

      [".haml", ".erb"].each do |type|
        ActionController::Base.view_paths.each do |path|
          path = path.to_s
          if File.exists?(path + sep + fn + type)
            l = fn
            break
          end
          if File.exists?(path + '/' + params[:controller] + sep + fn + type)
            l = fn
            break
          end
        end
      end
      l
    end
  end

  def dif(l)
    if browser_dif
      if is_mobile? || params[:fake_mobile]
        mobile_template(l)
      end 
    end

    l
  end

  unless config.consider_all_requests_local 
    rescue_from Exception, :with => :render_error
    rescue_from ActiveRecord::RecordNotFound, :with => :render_error
    rescue_from ActionController::RoutingError, :with => :routing_error
    rescue_from ActionController::UnknownController, :with => :render_error
    rescue_from AbstractController::ActionNotFound, :with => :render_error
  end

  def routing_error(exception)
      render_error(exception)
  end

  def render_error(exception, detail = '')
    @not_found = exception.instance_of?(ActionController::RoutingError)

    if @not_found && request.fullpath =~ /\.(gif|png|jpg|jpeg)/
      render :text=>"Not found", :status=>404
      return
    end

    if @not_found && Preference.get_cached(_sid, "page_not_found_url")
      render_page_by_url Preference.get_cached(_sid, "page_not_found_url")
      return
    end
    @reference = Digest::MD5.hexdigest(Time.now.to_s)[0..8]
    @exception = exception
    
    logger.error "Error reference: ***** #{@reference} #{@exception} #{request.fullpath} *****"
    session[:error_message] = "Page not found" if @not_found

    @notes = <<-HERE
Request: #{request.method} #{request.fullpath}
Controller: #{params.delete(:controller)}
Action: #{params.delete(:action)}
Parameters: #{params.collect { |k,v| "#{k} = #{v}\n" }.join(' ') }
Reference: #{@reference}
Timestamp: #{Time.now}

Exception Message: #{exception.message}
Error Messages: #{session[:error_message]}
Debug Error Message: #{session[:debug_error_message]}

User: #{current_user ? (current_user.id.to_s + ' ' + current_user.email) : ''}

Session: #{session.inspect}
#{detail.not_blank? ? detail : ''}
Stack Trace:\n
#{exception.backtrace.join("\n")}
HERE
    
    logger.debug @notes

    if Rails.env.development? && Preference.getCached(_sid, "log_errors")!="true"
      logger.debug @notes
      render "error/development", :layout=>false
    else 
      status = @not_found ? 404 : 500
      Event.store("#{status} error", request, current_user ? current_user.id : nil, @notes, @reference) unless status == 404
      error_template = PageTemplate.sys(_sid).where(:name=>Preference.get_cached(_sid, "error_template")).first
      if error_template
        inline_template = "<div id='page_#{page.id}' class='template_#{error_template.id}'>\n\n" + error_template.body + "\n\n</div>"
        render :inline=>inline_template, :layout=>error_template.layout.path, :type=>error_template.template_type || 'erb'
      else
        render "error/application", :layout=>Preference.getCached(_sid, "error_layout") || "application", :status=>status
      end
    end

    session[:error_message] = nil
  end

  def not_found_404
    super_render :text=>"not found", :status=>404, :layout=>false
  end

  def not_found
    raise ActionController::RoutingError.new("Page Not Found")
  end

  def no_read
    raise ActionController::RoutingError.new("Page Not Found (cannot read)")
  end

  def no_write
    raise ActionController::RoutingError.new("Page Not Found (cannot write)")
  end

  def edit_page_path(page)
    "/#{page.class.name.tableize.pluralize}/#{page.id}/edit"
  end

  def info_page_path(page)
    "/#{page.class.name.tableize.pluralize}/#{page.id}/info"
  end

  def page_path(page)
    "/#{page.class.name.tableize.pluralize}/#{page.id}"
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to "/error/401"
  end

  def can_use
    authenticate_user!
    authorize! :use, self.class
  end

  def can_moderate
    authenticate_user!
    authorize! :moderate, self.class
  end

  def user_sees_menu?
    current_user && current_user.sees_menu?
  end 

  def get_view_content(view = nil)
    if view==nil
      view_name = params[:view_name]
      view = View.where(:name=>view_name).sys(_sid).first
    end

    output = ''
    output = render_to_string(:inline=>view.header, :layout=>false)
    
    data = Page.joins("left join terms on terms.page_id = pages.id").where("page_template_id in (#{view.page_template_id})").sys(_sid)
    data = data.order(eval('"' + view.order_by.gsub('"', '\"') + '"')) if view.order_by.not_blank?
    data = data.where(eval('"' + view.where_clause.gsub('"', '\"') + '"')) if view.where_clause.not_blank?

    @pages = data.page(params[:page]).per(view.per_page)
    @pages.each do |page|
      @page = page
      output += render_to_string(:inline=>view.body, :layout=>false, :type=>view.template_type || 'erb')
    end
    output += render_to_string(:inline=>view.footer, :layout=>false, :type=>view.template_type || 'erb')
    return output
  end


  def link_to(name, href) 
    "<a href='#{href}' title='#{name}'>#{name}</a>"
  end

  def app_name
    Preference.get_cached(_sid, "app_name")
  end

 
  def show_form(form)
    @page_title = form.title
    if params[:edit]
      @sub = form.form_submissions.where(:id=>params[:edit]).first
      unless @sub && @sub.can_edit?(current_user)
        if current_user == nil
          redirect_to "/users/sign_in" and return
        end
        redirect_to "/" and return
      end
    end

    render "form/show", :layout=>((form.respond_to?(:layout) && form.layout) ? form.layout : 'application')
  end    
  
  def captcha_okay?
      if Form.validate_captcha_answer(params[:q_a], params[:q_q])
        return true
      else

        logger.info "*** ANTI SPAM: Failed captcha #{request.remote_ip} #{params[:controller]}##{params[:action]}"
        if current_user
          current_user.update_attributes(:spam_points => current_user.spam_points + 1) rescue nil
        end
        Event.store("captcha-failure", request, current_user ? current_user.id : nil )
        return false
      end

  end

  def sanity_check_okay?
    check = params[:check]
    unless check 
      logger.info "***** No form check code"
      redirect_to request.referer, :notice=>"Malformed submission" and return false
    end
    if SubmissionCheck.exists?(check)
      logger.info "**** Already submitted this form once"
      redirect_to request.referer, :notice=>"This has already been submitted" and return false
    end
    
    SubmissionCheck.record(check)

    return true
  end    
  
  def anti_spam_okay?
    if honeypot_fields.any? { |f,l| !params[f].blank? }
      head :ok
      logger.info "*** ANTI SPAM: Rejected due to honeypot in #{params[:controller]}##{params[:action]}"
      if current_user
        current_user.update_attributes(:spam_points => current_user.spam_points + 1)
      end
      Event.store("anti-spam", request, current_user ? current_user.id : nil )
      return false
    else
      return true
    end
  end

  def get_asset(id, code)
    @asset = Asset.where(:id=>id).first
    if @asset.code!=code
      redirect_to "/"
      return
    end

    send_file @asset.sys_file_path('original'), :type=>@asset.file_content_type, :x_sendfile=>true
  end

  def render_page_by_url(url)
    @page = Page.sys(_sid).where(:full_path=>url).first
    if (@page==nil || @page.deleted? || !@page.is_published?) 
      render "/error/404", :status=>404, :layout=>@page ? @page.dif_template(use_mobile?).layout.path : false
      return
    end 

    render_page(@page)
  end

  def render_page(page)
    template = page.dif_template(use_mobile?)
    inline_template = "<div id='page_#{page.id}' class='#{page.editable ? 'editing' : 'not_editing'} template_#{template.id} #{app_name}_page #{page.page_name}'>\n\n" + template.body + "\n\n</div>"

    render :inline=>inline_template, :layout=>template.layout.path, :type=>template.template_type || 'erb'
  end

  def csv_headers(filename)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
    end
  end

  def feature?(name)
    Preference.licensed?(_sid, name) 
  end

  def host_name
    Preference.get(_sid, "host_name")
  end

  def mailchimp_connect
    @gibbon = Gibbon.new(Preference.get_cached(_sid,'mailchimp_api_key'))
  end


  Pagebase = Page.includes([:page_contents_version0, {:page_template=>:layout}, {:block_instances0=>:block}])


end
