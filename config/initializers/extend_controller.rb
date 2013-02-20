module DomainController

  attr_accessor :kit_system


  def licensed(c = nil)
    if c!=nil
      function = c
    else
      params[:controller] =~ /^admin\/(.*)$/
      function = $1
    end

    if function
      return if Preference.licensed?(_sid, function)
      logger.info "**** Tried to access #{function} but not licensed"
      redirect_to "/db" and return
    end
  end

  def set_system_param(key)
    params[key][:system_id] = _sid
  end
 
  def set_system
    use_multiple_databases = Rails.configuration.use_multiple_databases rescue false

    if use_multiple_databases
      default_connection = get_default_connection
      default_database_name = default_connection["database"]
      make_db_connection(default_connection)
    end

    system_id = session[:system_id]
    unless system_id
      SystemIdentifier.all.each do |ident|
        if ident.ident_type == 'hostname' && request.host.downcase == ident.ident_value.downcase 
            system_id = ident.system_id
            break
        end
        if ident.ident_type == 'subdomain' && request.subdomains.first.downcase == ident.ident_value.downcase
          system_id = ident.system_id
          break
        end
        if ident.ident_type == 'port' && request.port.to_s == ident.ident_value
            system_id = ident.system_id
            break
        end
        if ident.ident_type == 'path' && request.fullpath == ident.ident_value
            system_id = ident.system_id
            break
        end
      end
 
      session[:system_id] = nil

      if system_id
        session[:system_id] = system_id
      else
        logger.error "_+_+_+_+_+_+_+_+ NO SYSTEM FOUND - nothing is going to work.  Do you need an entry in the system_identifiers table to match this scenario? Host: #{request.host.downcase} Subdomain: #{request.subdomains.first} Port: #{request.port} Path: #{request.fullpath} _+_+_+_+_+_+_+_+"
        session[:system_id] = 1
      end
    end

    self.kit_system = System.where(:id=>session[:system_id]).first
    if use_multiple_databases
      current_user.system = self.kit_system if current_user 
      logger.info "*** Master Database: #{default_database_name} Master System ID: #{self.kit_system.id} Database Connection: #{self.kit_system.database_connection || 'default'} System ID: #{_sid}"

      if self.kit_system.database_connection && self.kit_system.database_connection != default_database_name
        make_db_connection(get_connection(self.kit_system.database_connection, self.kit_system.database_username, self.kit_system.database_password))
      end
    else
      logger.info "*** System ID #{_sid}"
    end
  end

  def add_sid(p)
    params[p][:system_id] = _sid
  end

  def _sid
    self.kit_system.get_system_id
  end

  def _sids
    _sid.to_s
  end

  def use_mobile?
    if params[:_sdevice]
      cookies[:force_device] = params[:_sdevice]
    end

    if cookies[:force_device]=='mobile' || params[:_mobile] 
      return true
    elsif cookies[:force_device]=='full' || params[:_full] 
      return false
    else 
      return is_mobile?
    end
  end

  def browser_dif
    return false
  end

  @is_mobile = nil

  def is_mobile?
    if @is_mobile==nil
      browser = Browser.new(:ua=>request.env['HTTP_USER_AGENT'])
      @is_mobile = browser.mobile?
    end
  
    return @is_mobile
  end
  
  private 

  def get_connection(database, username, password)
     ActiveRecord::Base.connection.instance_variable_get("@config").dup.update(:database=>database, :username=>username, :password=>password)
  end
  
  def get_default_connection
    Rails.configuration.database_configuration[Rails.env]
  end
    
  def make_db_connection(connection)
    ActiveRecord::Base.establish_connection(connection)
  end

end
