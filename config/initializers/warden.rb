Rails.configuration.middleware.use RailsWarden::Manager do |manager|
    manager.default_strategies :cookie, :token, :email
    manager.failure_app = AccountController
  end

  Warden::Strategies.add(:cookie) do
    def valid?
      cookies[:sign_in]
    end

    def authenticate!
      u = User.cookie_authenticate(session[:system_id], cookies[:sign_in])

      success!(u) if u
    end
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
      success!(u) if u
    end
  end

  Warden::Strategies.add(:token) do
    def valid?
      session[:system_id] && params[(Preference.get_cached(session[:system_id], "account_token_param") || 'token').to_sym]
    end

    def authenticate!
      system_id = nil
      
      u = User.token_authenticate(session[:system_id], params[(Preference.get_cached(session[:system_id], "account_token_param") || 'token').to_sym]
)
      success!(u) if u
    end

  end


