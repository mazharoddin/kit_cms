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
    session[:return_to] ||= request.referer
    @page_title = "Sign In"
    self.kit_template = "user/sign-in"
    super
  end

end
