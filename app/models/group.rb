class Group < KitIndexed
  has_many :group_users
  has_many :users, :through=>:group_users

  has_many :category_groups
  has_many :groups, :through=>:category_groups
  
  after_create :mailchimp_create
  before_update :mailchimp_update
  before_destroy :mailchimp_delete
  validates :name, :uniqueness=>{:scope=>:system_id, :message=>"A group with that name already exists"}

  def mailchimp_create
    gibbon = mailchimp_connection
    begin
    gibbon.list_interest_group_add({:id=>Preference.get(self.system_id, 'mailchimp_all_user_list'), :group_name=>self.name, :grouping_id=>mailchimp_get_group_id}) 
    rescue Exception => e
      logger.info "Mailchimp_create in group.rb #{e.message}"
    end
  end

  def mailchimp_delete
      gibbon = mailchimp_connection
    begin
      gibbon.list_interest_group_del({:id=>Preference.get(self.system_id, 'mailchimp_all_user_list'), :group_name=>self.name, :grouping_id=>mailchimp_get_group_id}) rescue nil
    rescue Exception => e
      logger.info "Mailchimp_create in group.rb #{e.message}"
    end
  end

  def mailchimp_update
    if self.name_changed?
      gibbon = mailchimp_connection
      begin
      gibbon.list_interest_group_del({:id=>Preference.get(self.system_id, 'mailchimp_all_user_list'), :group_name=>self.name_was, :grouping_id=>mailchimp_get_group_id})    
      gibbon.list_interest_group_add({:id=>Preference.get(self.system_id, 'mailchimp_all_user_list'), :group_name=>self.name, :grouping_id=>mailchimp_get_group_id})    
    rescue Exception => e
      logger.info "Mailchimp_create in group.rb #{e.message}"
    end
    end
  end

  def self.mailchimp_groups(system_id)
    Group.sys(system_id).all.collect { |group| group.name } << "All"
  end

  def grant_permission_to_this_group
    Category.all.each do |category|
      CategoryGroup.create(:group_id=>self.id, :category_id=>category.id, :can_read=>1, :can_write=>0)
    end

    Category.build_permission_cache(self.system_id)
  end

  before_destroy :remove_permissions_for_this_group
  
  def remove_permissions_for_this_group
    CategoryGroup.delete_all("group_id = #{self.id}")
    Category.build_permission_cache(self.system_id)
  end

  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>190}

  def mailchimp_get_group_id
    groups = mailchimp_connection.list_interest_groupings({:id=>Preference.get_cached(self.system_id, 'mailchimp_all_user_list')}) 

    raise "no groups found" unless groups 
    group_id = nil
    groups.each do |group|
      if group["name"] == "KIT Groups"
        return group["id"]
      end
    end
    
    raise "no KIT Groups found" 
  end

  def mailchimp_connection
    Gibbon.new(Preference.get_cached(self.system_id,'mailchimp_api_key'))
  end
  
end

