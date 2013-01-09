class TopicCategory < ActiveRecord::Base
  has_many :topics, :order=>:display_order, :dependent=>:delete_all
  before_create :update_url

  has_many :topic_threads, :through=>:topics

  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>200}

  def update_url
    self.url = self.name.urlise
  end
  
  def link
    "/forums/category/#{self.url}"
  end

  def read_visibility
    Topic.visibility(self.read_access_level)
  end
  
  def write_visibility
    Topic.visibility(self.write_access_level)
  end

  def recent_threads(user, count)
    read_level = user ? user.forum_level : 0

    self.topic_threads.limit(count).order("topic_threads.id desc").where("topic_threads.is_visible = 1").includes(:topic).where("topics.read_access_level <= #{read_level}")
  end
end
