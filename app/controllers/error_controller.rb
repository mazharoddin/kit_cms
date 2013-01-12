class ErrorController < KitController
  
  def check_diag_only
    return true
  end
 
  def application
    
    id = params[:id]
    
    if id=='404'
      session[:error_message] ||= "We are sorry but we can't find that page"
    elsif  id=='401'
      session[:error_message] ||= "Not authorised"
    else
      session[:error_message] ||= "An error occurred processing your request.  Please follow the links on our home page and try again."
    end
    
    render "error/application", :layout=>"application"
    
    session[:error_message] = nil
    session[:debug_error_message] = nil
  end
  
end
