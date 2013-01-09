class User < GnricIndexed

  User.do_indexing :User, [
    {:name=>"id", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"system_id", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"email", :boost=>50},
    {:name=>"display_name", :boost=>10},
    {:name=>"attributes", :as=>"self.user_attribute_values.map {|uav| {uav.user_attribute.id.to_s => uav.value}}"},
    {:name=>"system_id", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"groups", :as=>"self.groups.map {|g| g.name}", :boost=>50},
    {:name=>"group_ids", :as=>"self.groups.map {|g| g.id}"}
  ]

  has_many :user_thread_views
  has_many :experiments
  has_many :goals_users
  has_many :notices_users
  has_many :notices, :through=>:notices_users
  has_many :assets, :class_name=>"UserAsset"
  has_many :calendars
  has_many :ads
  has_many :ad_clicks
  has_many :calendar_entries
  has_many :user_links
  has_many :user_notes
  has_many :created_user_notes, :foreign_key=>"created_by"
  has_many :group_users
  has_many :groups, :through=>:group_users
  has_many :page_favourites
  has_many :pages, :through=>:page_favourites
  has_one :forum_user
  has_many :page_edits
  has_many :events  
  has_many :mappings
  has_many :page_comments
  has_many :conversation_users
  has_many :conversations, :through=>:conversation_users
  has_many :user_attribute_values
  has_many :user_attributes, :through=>:user_attributes_values
  has_many :atts, :class_name=>"UserAttributeValue"
  has_many :topic_thread_users
  has_many :topic_threads, :through=>:topic_thread_users
  belongs_to :system
  has_many :form_submissions
  has_many :topic_post_votes

  # this is like our own version of eager loading, because we can't use the system_id in normal eager loading
  def self.load_forum_attributes(system_id, users)
    ids = users.keys.join(',')
    return if ids.is_blank?

    attributes_to_load = Preference.get_cached(system_id, "user_attributes_to_load")
    return unless attributes_to_load

    atts = eval(attributes_to_load)

    users.each do |id, user|
      user.loaded_atts = {}
    end

    UserAttributeValue.where("user_attribute_id in (#{atts.keys.join(',')})").where("user_id in (#{ids})").each do |uav|
      users[uav.user_id].loaded_atts[atts[uav.user_attribute_id]] = uav
    end  
  end

  attr_accessor :loaded_atts

  def loaded_attributes(name)
    unless loaded_atts
      User.load_forum_attributes(self.system_id, { self.id => self } )
    end 
    
    return loaded_atts ? loaded_atts[name] : nil
  end

  def system_filter_sql 
    "system_id = #{self.system_id}"
  end

  def method_missing(meth, *args, &block)
    if meth =~ /^image_(.*)$/
      return attribute_image($1, args[0]) 
    end

    if UserAttribute.where(:code_name=>meth).first
      return attribute_value(meth)
    end
    super
  end

  has_and_belongs_to_many :roles
  after_create { Activity.add(self.system_id, "New user registered <a href='/admin/user/#{self.id}'>#{self.email}</a>", 1, 'Users') }  

  after_save :check_spam_points

  def forum_rating(cant_be_negative = true, min_votes = 0)
    return nil if self.forum_votes < min_votes

    r = self.forum_votes.to_f / self.forum_points.to_f * 100

    r = 0 if r < 0 && cant_be_negative

    "%d" % r rescue nil
  end

  def active_for_authentication?
    super && self.banned_at == nil
  end

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :lockable,
         :maximum_attempts=>10, :unlock_strategy=>:time

  if Rails.configuration.use_rest_auth
    devise :encryptable, :encryptor => :restful_authentication_sha1
  end

  after_create :welcome_message

  validates :display_name, :uniqueness=>{:scope=>:system_id}
  validates :email, :presence=>true, :uniqueness=>{:scope=>:system_id}
  validates :password, :presence=>true, :confirmation=>true, :on=>:create
  validates_confirmation_of :password, :on=>:create

  attr_accessible :email, :password, :password_confirmation, :remember_me, :display_name, :subscribe_newsletter, :spam_points, :system_id
  
  attr_accessor :fave_pages

  def concatenated_groups
    self.groups.map {|g| g.name}.join(", ")
  end
  
  def attribute_value(name)
    self.user_attribute_values.where(["user_attributes.name = ?", name]).joins(:user_attribute).first.value rescue nil
  end
  
  def attribute_image(name, size)
    self.user_attribute_values.where(["user_attributes.name = ?", name]).joins(:user_attribute).first.asset.url(size) rescue nil
  end

  def heard_from!
    User.connection.execute("update users set last_heard_from=now() where id = #{self.id}")
  end

  def lock_access!
    Activity.add(self.system.id, "Locking user <a href='/admin/user/#{self.id}'>#{self.email}</a> after #{self.failed_attempts} failed attempts", 0, "Users")
    super   
  end 

  def load_favourite_pages
    unless self.fave_pages
      self.fave_pages = Hash.new
      pages.each do |pu|
        self.fave_pages[pu.id] = 1
      end
    end
  end
  
  def is_favourite_page?(page_url)
    load_favourite_pages
    return self.fave_pages[page_url.id]==1
  end
  
  def favourites_pages_comma
    load_favourite_pages
    fave_pages.keys.join(',')
  end
  
  def role?(role)
    users_roles = Rails.cache.fetch(self.role_cache_key, :expires_in => 10.minutes) do
      ur = {}
      self.roles.map {|role| ur[role.name.camelize.downcase] = true}
      ur
    end

    users_roles[role.camelize.downcase] ? true : false
  end
  
  def sees_menu?
    admin? || editor?
  end

  def moderator?
    role?("Forum Moderator") 
  end

  def admin?
    role?("Admin") || role?("SuperAdmin")
  end

  def superadmin?
    role?("SuperAdmin")
  end

  def designer?
    role?("Designer") || role?("SuperAdmin")
  end

  def editor?
    role?("Editor") || role?("SuperAdmin") || role?("Admin") || role?("Designer")
  end  

  # an elevating numerical representation of the various roles
  def ranking
    return 10 if self.superadmin?
    return 8 if self.designer?
    return 7 if self.admin?
    return 5 if self.editor?
    return 3 if self.moderator?
    return 1
  end

  def unban!(current_user_id = nil)
    self.banned_at = nil
    self.save
    Activity.add(self.system.id, "UnBanning user <a href='/admin/user/#{self.id}'>#{self.email}</a>", 0, "Users")
    self.user_notes << UserNote.new(:category=>"Ban", :description=>"Unbanned", :created_by_id=>current_user_id)
  end

  def ban!(current_user_id = nil)
    return if self.email == 'gnric@dsc.net'
    self.banned_at = Time.now
    self.save
    Activity.add(self.system.id, "Banning user <a href='/admin/user/#{self.id}'>#{self.email}</a>", 0, "Users")
    self.user_notes << UserNote.new(:category=>"Ban", :description=>"Banned", :created_by_id=>current_user_id)
  end

  def not_banned?
    self.banned_at == nil
  end

  def active?
    super && self.not_banned?
  end

  def add_role(role, current_user_id = nil)
    r = Role.where(:name=>role).sys(self.system.id).first
    return nil unless r
    Activity.add(self.system.id, "Adding role '#{role}' to user <a href='/admin/user/#{self.id}'>#{self.email}</a>", 0, "Users")
    self.user_notes << UserNote.new(:category=>"Role", :description=>"Added to role #{role}", :created_by_id=>current_user_id)
    self.roles << r 
    Rails.cache.delete(self.role_cache_key)
  end

  def remove_role(role, current_user_id = nil)
    r = Role.where(:name=>role).sys(self.system.id).first
    return nil unless r
    Activity.add(self.system.id, "Removing role '#{role}' to user <a href='/admin/user/#{self.id}'>#{self.email}</a>", 0, "Users")
    self.user_notes << UserNote.new(:category=>"Role", :description=>"Removed from role #{role}", :created_by_id=>current_user_id)
    self.roles.delete(r)
    Rails.cache.delete(self.role_cache_key)
  end 

  def role_cache_key
    "user_#{self.id}_roles"
  end

  def moderator_status(set) 
    set ? self.add_role('Forum Moderator')  : self.remove_role('Forum Moderator')
  end

  def designer_status(set)
    set ? self.add_role('Designer') : self.remove_role('Designer')
  end

  def admin_status(set)
    set ? self.add_role('Admin')  : self.remove_role('Admin')
  end

  def welcome_message
    Notification.welcome_message(self, self.system_id).deliver unless Preference.get(self.system_id, "no_signup_confirmation")=='true'
  end

  def check_spam_points
    max = (Preference.getCached(self.system_id, 'spam_points_to_ban_user') || "10").to_i
    return unless self.spam_points
    if self.spam_points >= max
      self.banned_at = Time.now
      Activity.add(self.system_id, "Banning user <a href='/admin/user/#{self.id}'>#{self.email}</a> due to accumulated spam-type activity", 0, "Users")
      self.user_notes << UserNote.new(:category=>"Ban", :description=>"Accumulation of spam points exceeding #{max}", :created_by_id=>0)
    end
  end

  def links
    return self.user_links.order("id") if self.user_links.size>0

    return UserLink.where("user_id is null").order("id").all
  end

  def short_display
    self.email.split('@')[0]
  end

  def mailchimp_connection
    Gibbon.new(Preference.get_cached(self.system_id,'mailchimp_api_key'))
  end
  
end
