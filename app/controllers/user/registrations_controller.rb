class User::RegistrationsController < Devise::RegistrationsController
  append_view_path Layout.resolver
  include DomainController
  include DeviseExtender

  before_filter :set_system
  before_filter { params[:user][:system_id] = _sids if params[:user]}
  before_filter :check_captcha, :only=>[:create] 
  layout "application"

  def after_sign_up_path_for(resource)
    path = session[:return_to] || "/"
    session[:return_to] = nil
    return path.to_s
  end

  def create
    self.kit_template = "user/register" 
    build_resource
    @attributes = UserAttribute.sys(_sid).where(:show_on_signup=>1).all

    if resource.save
      user = resource
      @attributes.each do |attr|
        if params[attr.code_name]
          uav = UserAttributeValue.new
          uav.user_attribute_id = attr.id
          uav.user_id = user.id
          uav.value = params[attr.code_name]
          uav.updated_by = current_user
          uav.system_id = _sid
          uav.save
        end
      end if @attributes
      if params[:groups]
        params[:groups].split(',').each do |gg|
          group = Group.find_sys_id(_sid, gg)
          user.groups << group
        end
      end
      resource.update_index
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        redirect_to after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  def new
    @page_title = "Sign Up"
    self.kit_template = "user/register"

    session[:captcha_okay] = true
    if params[:return_to]
      session[:return_to] = params[:return_to]
    elsif url = Preference.get_cached(_sid, "url_after_sign_up")
      session[:return_to] = url
    else
      session[:return_to] ||= request.referer
    end

    @attributes = UserAttribute.sys(_sid).where(:show_on_signup=>1).all
    super
  end

  def update
    @page_title = "Edit Account"
    self.kit_template = "user/edit"
    super
  end

  def edit 
    @page_title = "Edit Account"
    self.kit_template = "user/edit"
    super
  end

  private 
  def check_captcha
    if Preference.get(_sid, "use_captcha")=='true'
      unless captcha_okay?
        flash[:error] = "You didn't answer the 'Are you human?' question correctly"
        redirect_to request.referer 
        return false
      end
    end

    return true
  end

  def captcha_okay?
      if session[:captcha_okay]==true || Form.validate_captcha_answer(params[:q_a], params[:q_q])
        session[:captcha_okay] = true
        return true
      else
        logger.info "*** ANTI SPAM: Failed captcha #{request.remote_ip} #{params[:controller]}##{params[:action]}"
        Event.store("captcha-failure", request, nil )
        return false
      end
  end
  
end
