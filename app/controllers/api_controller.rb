class ApiController < ActionController::Base
  include DomainController

  before_filter :set_system, :except=>[:not_found_404]
  before_filter :offline, :except=>[:not_found_404, :down_for_maintenance]

  after_filter :clear_session

  def clear_session
    session.clear
    request.session_options[:skip] = true
  end

  def protect_against_forgery?
  end

  rescue_from Exception, :with => :respond_error

  def respond_error(exception)
    head :internal_server_error

    logger.error exception.message
  end

  def offline
    message = Preference.get_cached(_sid, "down_for_maintenance_message")
    if message
      head :service_unavailable, :message=>message
      return false
    end
  end

end

