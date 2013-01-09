class UserObserver < ActiveRecord::Observer

  def after_create(user)
    return unless gibbon = mailchimp(user)

    gibbon.list_subscribe({:id=>Preference.get_cached(user.system_id, "mailchimp_all_user_list"), :email_address=>user.email, :double_optin=>false})
    Activity.add(user.system_id, "Subscribed '#{user.email}'", 0, "Mailchimp")
  end

  def before_delete(user)
    return unless gibbon = mailchimp(user)
    gibbon.list_unsubscribe({:id=>Preference.get_cached(user.system_id, "mailchimp_all_user_list"), :email_address=>user.email, :delete_member=>true})
    Activity.add(user.system_id, "Deleted '#{user.email}'", 0, "Mailchimp")
  end
  
  def before_save(user)

  end

  def mailchimp(user)
    key = Preference.get_cached(user.system_id, "mailchimp_api_key") 
    return nil unless key
    return Gibbon.new(key)
  end
end
