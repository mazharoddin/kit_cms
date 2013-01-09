class GroupUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  after_save :mailchimp_update_groups
  after_destroy :mailchimp_update_groups

  def mailchimp_update_groups
    return unless Preference.get_cached(self.user.system_id, "mailchimp_api_key").not_blank?

    gb = mailchimp_connection
    gb.list_subscribe({:id=>Preference.get(self.user.system_id, "mailchimp_all_user_list"), :email_address=>self.user.email, :merge_vars=>{:GROUPINGS=>[{:name=>"KIT Groups", :groups=>self.user.groups.collect {|g| g.name}.join(',')}]}, :update_existing=>true}) 
  end

  def mailchimp_connection
    Gibbon.new(Preference.get_cached(self.user.system_id,'mailchimp_api_key'))
  end
end
