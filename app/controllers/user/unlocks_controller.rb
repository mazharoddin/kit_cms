class User::UnlocksController < Devise::UnlocksController
  append_view_path Layout.resolver
  include DomainController
  include DeviseExtender

  helper_method :stylesheets
  
  before_filter :set_system
  before_filter { params[:user][:system_id] = _sids if params[:user]}
  
  layout "application"

end
