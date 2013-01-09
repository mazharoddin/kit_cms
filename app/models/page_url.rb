class PageUrl < ActiveRecord::Base
  has_many :page_favourites
  has_many :favourite_users, :through=>:page_favourites, :source=>"user"
  has_many :page_comments
  has_many :page_edits
  has_many :page_auto_saves

  has_many :topic_threads, :through=>:page_url_threads
  has_many :page_url_threads
  cattr_reader :per_page
  @@per_page = 10

  def recent_threads(count, user)
    level = user ? user.forum_level : 0

    self.topic_threads.limit(count).order("topic_threads.id desc").includes(:topic).where("topic_threads.is_visible = 1 and topics.is_visible = 1 and topics.read_access_level <= #{level}")
  end

  def self.update(page)
    pu = PageUrl.where(:page_id=>page.id).where(:page_type=>page.class.name.tableize).first
    
    pu ||= PageUrl.new(:page_id=>page.id, :page_type=>page.class.name.tableize)
    pu.full_path = page.full_path
    pu.name = page.name
    pu.title = page.title
    pu.category_id = page.category_id
    pu.status_id = page.status_id
    pu.tags = page.tags
    pu.save
  end
  
  def link(mode='show', inplace_edit=false)
    if mode=='show'
      return self.full_path + (inplace_edit ? "?edit=1" : "")
    else
      return "/#{self.page_type}/#{self.page_id}/#{mode}"
    end
  end
    
  def is_favourite?(current_user)
    current_user.is_favourite_page?(self)
  end
    
  
end
