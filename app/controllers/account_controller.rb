require 'digest/md5'

# TODO: password reset
# TODO: 
#


class AccountController < KitController

  before_filter :redirect_current, :only=>[:sign_in, :sign_up, :forgotten]

  def edit
    redirect_to sign_in_url unless current_user

    if request.post?
      user.email = params[:email] unless params[:must_change_password]
      if params[:must_change_password] || params[:password].not_blank? || params[:password_confirmation].not_blank?
        user.skip_password = false
        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
      else
        user.skip_password = true
      end      
      if user.save
        redirect_after_signin(:edit)
        return
      end
    end

    render_action "edit"
  end

  def forgotten
    if request.post? && (params[:email].not_blank? || (params[:user] && params[:user][:email].not_blank?))
      u = User.sys(_sid).where(:email=>(params[:email] || params[:user][:email])).first
      if u
        u.skip_password = true
        u.reset_password_token = Digest::MD5.hexdigest(u.email + Time.now.to_s + rand(100000).to_s)
        u.reset_password_sent_at = Time.now
        u.save!
        Notification.forgotten_password(u.id).deliver
        Activity.add(_sid, "Sent password reset to user <a href='/admin/user/#{u.id}'>#{u.email}</a>", nil, "Users")
      end 
      redirect_to sign_in_url, :notice=>t("account.reset_sent")
      return
    end

    render_action("forgotten")
  end

  def reset
    code = params[:code]

    u = User.sys(_sid).where(:reset_password_token=>params[:code]).where("reset_password_sent_at >= date_sub(now(), interval 24 hour)").where("reset_password_token is not null").first

    if u
      warden.set_user u
      u.skip_password = true
      u.record_signin(_sid, request)
      u.reset_password_token = nil
      u.save
      render_action("edit", {:notice=>t("account.change_your_password"), :dont_show_intro=>true, :dont_show_leave_blank_passwords=>true, :must_change_password=>true})
    else
      render_action("forgotten", :notice=>t("account.reset_failed"))
    end
  end

  def unauthenticated
    store_sign_in_redirect

    if params[(Preference.get_cached(_sid, "account_token_param") || 'token').to_sym]
      authenticate
      if current_user
        current_user.record_signin(_sid, request)
        redirect_after_signin(:token)
      else
        redirect_after_signin(:token, true)
      end
      return
    end

    redirect_to_signin
  end

  def sign_up
    new_user = nil

    if request.post? 
      new_user = User.new
      new_user.skip_password = false
      new_user.email = params[:email] || params[:user][:email]
      new_user.password = params[:password] || params[:user][:password]
      new_user.password_confirmation = params[:password_confirmation] || params[:user][:password_confirmation]
      new_user.system_id = _sid
      new_user.sign_up_ip = request.remote_ip

      if new_user.save
        process_new_user(new_user)
        warden.set_user new_user
        new_user.record_signin(_sid, request)
        redirect_after_signup
        return
      end
    end
    @user = new_user
    render_action("sign_up")
  end

  def sign_in
    if request.post?
      authenticate
      if current_user
        current_user.record_signin(_sid, request)
        if params[:remember_me]
          remember_for = (Preference.get_cached(_sid, "account_remember_for_days") || "90").to_i
          cookies[:sign_in] = { :value=> current_user.remember_token, :expires=> remember_for.days.from_now }
        end
        redirect_after_signin(:email)
        return
      else
        u = User.record_failed_signin(_sid, request)
      end
    end

    render_action("sign_in")
  end

  def sign_out
    if current_user
      if current_user.respond_to?(:last_sign_out)
        current_user.update_attributes(:last_sign_out=>Time.now)
      end
      current_user.dont_remember
      warden.logout
      
    end

    redirect_to params[:url] || pref("url_after_sign_out") || "/"
  end

  protected
  def process_new_user(u)
    attributes = UserAttribute.sys(_sid).where(:show_on_signup=>1).all

    attributes.each do |attr|
        if params[attr.code_name]
          uav = UserAttributeValue.new
          uav.user_attribute_id = attr.id
          uav.user_id = u.id
          uav.value = params[attr.code_name]
          uav.updated_by = u.id
          uav.system_id = _sid
          uav.save
        end
    end if attributes

      if params[:groups]
        params[:groups].split(',').each do |gg|
          group = Group.find_sys_id(_sid, gg)
          user.groups << group
        end
      end
      u.update_index
  end

  def redirect_after_signup
    url = url_after_signup 

    redirect_to url
  end

  def redirect_after_signin(mode, failed = false)
    if mode==:token
      if failed
        redirect_after_signin_token_failed
      else
        redirect_after_signin_token
      end
    elsif mode==:email || mode==:edit
      if failed 
        redirect_after_signin_email_failed
      else
        redirect_after_signin_email
      end
    else 
      redirect "/"
    end
  end

  def redirect_after_signin_token
    redirect_to url_after_signin
  end

  def redirect_after_signin_token_failed
    redirect_to "/"
  end

  def redirect_after_signin_email
    redirect_to url_after_signin
  end

  def redirect_after_signin_email_failed
    redirect_to "/users/sign_in"
  end

  def url_after_signup
    path = session[:return_to] || url_after_group(:signup) || url_after_group(:signin) || '/'
    session[:return_to] = nil
    return path.to_s
  end

  def url_after_signin
    path = session[:return_to] || url_after_group(:signin) || "/"
    session[:return_to] = nil
    return path.to_s
  end

  def url_after_group(mode)
    Preference.sys(_sid).where("name like 'account_after_#{mode}_%'").all.each do |pref|
      pref.name =~ /^account_after_#{mode}_(.*)$/
      if user.groups.where(:name=>$1).count>0
        return pref.value
      end
    end

    return nil
  end

  def redirect_to_signin
    redirect_to sign_in_url
  end

  def store_sign_up_redirect
    if params[:return_to]
      session[:return_to] = params[:return_to]
    elsif url = pref("url_after_sign_up")
      session[:return_to] ||= url
    end
    session[:return_to] = nil if session[:return_to] == sign_up_url
  end

  def store_sign_in_redirect
    if params[:return_to]
      session[:return_to] = params[:return_to]
    elsif url = pref("url_after_sign_in")
      session[:return_to] ||= url
    else
      session[:return_to] ||= env['warden.options'][:attempted_path]
    end

    session[:return_to] = nil if session[:return_to] == sign_in_url
  end    

  def render_action(name, options = {})
    flash[:notice] = options[:notice] if options[:notice]
    flash[:error] = options[:error] if options[:error]

    if params[:custom]
      @page = Pagebase.sys(_sid).where(:full_path=>URI(request.referer).path).first
      if @page
        render_page(@page)
        return
      end
    end

    if page_id = pref("account_#{name}_pageid") && @page = Pagebase.sys(_sid).where(:id=>page_id.to_i).first
      if @page
        render_page(@page)
        return
      end
    end
  
    options[:layout] = pref("account_#{name}_layout") || "application"
    @options = options
    render name, options
  end    

  def sign_in_url
    view_context.sign_in_url
  end

  def sign_up_url
    view_context.sign_up_url
  end

  def sign_out_url
    view_context.sign_out_url
  end

  def redirect_current
    if current_user
      redirect_to "/" 
      return false
    else
      return true
    end
  end
end
