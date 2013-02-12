Rails.configuration.middleware.use RailsWarden::Manager do |manager|
    manager.default_strategies :email, :token
    manager.failure_app = AccountController
  end


  Warden::Strategies.add(:email) do

    def valid?
      session[:system_id] && 
        (
          ( params[:email] && params[:password] ) ||
          ( params[:user] && params[:user][:email] && params[:user][:password] )
        )
    end

    def authenticate!
      u = User.authenticate(session[:system_id], params[:email] || (params[:user] && params[:user][:email]), params[:password] || (params[:user] && params[:user][:password]))
      u.nil? ? fail!("Could not login") : success!(u)
    end
  end

  Warden::Strategies.add(:token) do
    def valid?
      session[:system_id] && params[(Preference.get_cached(_sid, "account_token_param") || 'token').to_sym]
    end

    def authenticate!
      system_id = nil
      
      u = User.token_authenticate(session[:system_id], params[(Preference.get_cached(_sid, "account_token_param") || 'token').to_sym]
)
      u.nil? ? fail!("Could not login") : success!(u)
    end

  end


