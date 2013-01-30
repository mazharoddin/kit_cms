class Category < KitIndexed

    Category.do_indexing :Category, [
      {:name=>"id", :index=>:not_analyzed, :include_in_all=>false},
      {:name=>"system_id", :index=>:not_analyzed},
      {:name=>"name"},
      {:name=>"path"}
    ]
  
  has_many :category_groups
  has_many :groups, :through=>:category_groups
  belongs_to :parent, :class_name=>"Category"
  has_many :pages

  before_destroy :remove_permissions_to_this_category
  after_create :grant_permissions_to_new_category
  before_save :update_path
  after_save :update_paths
  after_save :clear_cache
  after_destroy :clear_cache
  has_many :children, :class_name=>"Category", :foreign_key=>:parent_id, :order=>:name
  has_many :visible_children, :class_name=>"Category", :foreign_key=>:parent_id, :conditions=>"is_visible = 1", :order=>:name
  
  validates :name, :length=>{:minimum=>1, :maximum=>200}, :format=>{:with=>/^[a-z0-9\.\-]+$/i, :message=>"Only letters, numbers, hypen and fullstop allowed"}, :unless=>"parent_id==0"
  validate :name_must_be_unique
 
  attr_accessor :parent_of

  def name_must_be_unique
    cnt = Category.sys(self.system_id).where(:name=>self.name).where(:parent_id=>self.parent_id).where(["id<>?", self.new_record? ? -1 : self.id]).count
    if cnt > 0
      errors.add(:name, "not unique within this category")
    end
  end

  def full_path 
    self.path
  end  

  def clear_cache
    Category.clear_cache(self.system_id)
  end

  def Category.cache_key(sid)
    return "_tree-#{sid}"
  end

  def Category.clear_cache(sid)
    Rails.cache.delete(Category.cache_key(sid))
  end

  def copy_permissions_to_subs
    Category.where(:parent_id=>self.id).all.each do |child|
      child.is_readable_anon = self.is_readable_anon
      child.save
      CategoryGroup.delete_all(["category_id = ?", child.id])
      category_groups.each do |cg|
        CategoryGroup.create(:category_id=>child.id, :group_id=>cg.group_id, :can_read=>cg.can_read, :can_write=>cg.can_write)
      end
      child.copy_permissions_to_subs
    end    
    Category.build_permission_cache(self.system_id)
  end

  def grant_permissions_to_new_category
    CategoryGroup.where(:category_id=>self.parent_id).all.each do |cg|
      CategoryGroup.create(:category_id=>self.id, :group_id=>cg.group_id, :can_read=>cg.can_read, :can_write=>cg.can_write)
    end
    Category.build_permission_cache(self.system_id)
  end

  def grant_read_permissions_to_all_groups
    Group.all.each do |group|
      CategoryGroup.create(:group_id=>group.id, :category_id=>self.id, :can_read=>1, :can_write=>0)
    end
    Category.build_permission_cache(self.system_id)
  end


  def set_readable_anon(readable)
    self.is_readable_anon = readable

    self.save
   Category.build_permission_cache(self.system_id)
  end

  def remove_permissions_to_this_category
    CategoryGroup.delete_all("category_id = #{self.id}")
    Category.build_permission_cache(self.system_id)
  end

  # all categories, in depth order (root at the top)
  def self.tree_by_depth(sid)
    Category.sys(sid).includes(:category_groups).all.sort do |a,b| 
      if a.depth < b.depth
        -1
      elsif a.depth > b.depth
        1
      else
        if a.name < b.name
          -1
        elsif a.name > b.name
          1
        else
          0
        end
      end
    end
  end

  # all categories, in a hash keyed by parent_id
  def self.tree_by_parent(sid)
    tree = {}

    Category.sys(sid).all.each do |c|
      tree[c.parent_id] ||= []
      tree[c.parent_id] << c
    end 

    return tree
  end

  # all categories, in a hash keyed by category_id, with "parent_of" attribute populated with a list of child categories AND child documents
  def self.tree_with_children(sid)
    lookup = { }
    cats = Category.sys(sid).order(:name).all
    
    cats.each do |cat|
      cat.parent_of = []
      lookup[cat.id] = cat
    end 

    cats.each do |cat|
      next if cat.is_root?

      lookup[cat.parent_id].parent_of << cat
    end

    Page.sys(sid).order(:name).includes(:status).find_each do |page|
      lookup[page.category_id].parent_of << page
    end
 
   return lookup 
  end

  @@perms_cache = {} 

  def user_can_read?(user)
    return true if self.is_readable_anon==1
    return false unless user
    user.groups.each { |group| 
      return true if group_can_read?(group) 
    }
    return true if user.superadmin?
    return false
  end

  def group_can_read?(group)
    group_can?(group, :read_groups)
  end

  def group_can_write(group)
    group_can?(group, :write_groups)
  end
  
  def group_can?(group, perm)
    if @@perms_cache[self.system_id]==nil
      @@perms_cache[self.system_id] = Category.build_permission_cache(self.system_id)
    end

    if @@perms_cache[self.system_id][self.id][perm][group.id]
      return true
    else
      return false
    end
  end

  def self.permission_cache(sid)
    @@perms_cache[sid] || Category.build_permission_cache(sid)
  end

  def self.build_permission_cache(sid)
    @@perms_cache[sid] = {}
    all_groups = {}
    Group.where(:system_id=>sid).all.collect { |g| all_groups[g.id] = g.name }
    Category.tree_by_depth(sid).each do |cat|
      permissions = @@perms_cache[sid][cat.parent_id] ? @@perms_cache[sid][cat.parent_id].clone : { :read_groups=>{}, :write_groups=>{} } # start with permissions of parent

      read_groups = {}
      write_groups = {}
      cat.category_groups.each do |g| 
        read_groups[g.group_id] = all_groups[g.group_id] if g.can_read==1
        write_groups[g.group_id] = all_groups[g.group_id] if g.can_write==1
      end 
      permissions[:read_groups] = read_groups
      permissions[:write_groups] = write_groups

      @@perms_cache[sid][cat.id] = permissions
    end

    return @@perms_cache[sid]
  end

  def depth
    self.parent_id==0 ? 0 : self.path.split("/").size-1
  end

  
  def Category.random
    c = Category.new
    c.name = rand(100000).to_s
    c.parent_id = 1 
    c.is_visible = true
    c.is_readable_anon = true
    c.save!
    c.name = "cat-#{c.id}"
    c.save!

    return c
  end  
 
  def update_paths
    self.update_page_paths

    children.all.each do |cat|
      cat.update_paths
    end
  end

  def update_page_paths
    Page.where(:category_id=>self.id).all.each do |p|
      p.skip_history = true
      p.save! 
    end
  end

  def has_contents?
    return true if children.count > 0
    return true if Page.where(:category_id=>self.id).limit(1).first
    return false
  end
  
  def documents(order = 'name')
    Page.where(:category_id=>self.id).order(order).all
  end
  
  def Category.update_all_paths(sid)
    Category.sys(sid).find_each do |c|
      c.save!
    end
  end
  
  def Category.root(sid)
    Category.find_by_parent_id_and_system_id(0,sid)
  end
 
  def is_root?
    self.parent_id == 0
  end

  def update_path
    # walk up path of parents until we reach the root
    self.path = self.get_full_path
  end

  def copy_to(category, deep = false) 
    new_cat = self.dup
    new_cat.save

    new_cat.make_child_of(category)

    if deep
      self.children.each do |child_cat|
        child_cat.copy_to(new_cat, true)
      end 
      self.pages.each do |page|
        page.copy_to(new_cat) 
      end
    end

    return new_cat.id 
  end
  
  def make_child_of(new_parent) 
    self.parent = new_parent
    self.save

    tree_with_children = Category.tree_with_children(self.system_id)  
    self.update_path_of_offspring(tree_with_children)

  end

  # relies on category.parent_of being populated, as it is by tree_with_children
  def update_path_of_offspring(tree)
  
    cat = tree[self.id]

    cat.parent_of.each do |item|
      # update me, then things I'm parent of
      logger.debug("Doing item #{item.id} which is a #{item.class.name}")
      item.skip_history = true if item.instance_of?(Page)
      item.save(:validate=>false) # force a path update
      item.update_path_of_offspring(tree) if item.instance_of?(Category)
    end 
  end

  def get_full_path
    "/" + self.get_parent_path.reverse.join('/')
  end
  
  def get_parent_path
    
    path = []
    c = self
    
    done = false
    
    while !done
      if c.parent_id == 0
        done = true
      else
        path << c.name
        c = c.parent
      end
    end
    
    return path
  end

  def self.create_default(sid)
    Category.create(:name=>"/", :parent_id=>0, :is_visible=>1, :path=>"/", :is_readable_anon=>1, :system_id=>sid)
  end
end
