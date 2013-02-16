module AccountHelper
  include KitHelper

  def users_have_profiles?
    UserAttribute.sys(_sid).where(:owner_editable=>1).count>0
  end

  def account_forgotten(options = {})
    render :partial=>"account/forgotten", :locals=>{:options=>options}
  end

  def account_sign_in_form(options = {})
    render :partial=>"account/sign_in", :locals=>{:options=>options}
  end

  def account_sign_up_form(options = {})
    render :partial=>"account/sign_up", :locals=>{:options=>options}
  end

  def account_edit_form(options = {})
    render :partial=>"account/edit", :locals=>{:options=>options}
  end

  def sign_up_url
    sys_pref("account_sign_up_url") || "/users/sign_up"
  end

  def sign_in_url
    sys_pref("account_sign_in_url") || "/users/sign_in"
  end

  def sign_out_url
    sys_pref("account_sign_out_url") || "/users/sign_out"
  end

  def forgotten_url
    sys_pref("account_forgotten_url") || "/users/forgotten"
  end

  def reset_url
    sys_pref("account_reset_url") || "/users/reset"
  end

  def account_reset_failed(options = {})
    render :partial=>"account/account_reset_failed", :locals=>{:options=>options}
  end
end
