class User::SessionsController < Devise::SessionsController
  append_view_path Layout.resolver
  include DomainController
  include DeviseExtender

  before_filter :set_system
  before_filter { params[:user][:system_id] = _sids if params[:user]}
  
  layout "application"

  def after_sign_in_path_for(resource)
    path = session[:return_to] || "/"
    session[:return_to] = nil
    return path.to_s
  end

  def new
    @page_title = "Sign In"
    self.kit_template = "user/sign-in"
    if params[:return_to]
        session[:return_to] = params[:return_to]
    elsif url = Preference.get_cached(_sid, "url_after_sign_up")
        session[:return_to] = url
    else
        session[:return_to] ||= request.referer
    end
    
    super
  end

end
