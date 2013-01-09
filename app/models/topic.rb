class Topic < ActiveRecord::Base
  has_attached_file :image, :styles=>{:thumb=>"100x100>"}

  belongs_to :topic_category
  has_many :topic_threads, :order=>"last_post_at desc", :dependent=>:destroy
  has_many :visible_topic_threads, :conditions=>"is_visible=1", :order=>"last_post_at desc", :class_name=>"TopicThread", :foreign_key=>:topic_id
  
  before_create :update_url
  
  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>200}
  validates :topic_category_id, :presence=>true

  has_one :last_thread, :class_name=>"TopicThread", :order=>"topic_threads.id desc", :conditions=>"is_visible=1"

  belongs_to :last_post, :class_name=>"TopicPost", :include=>:created_by_user

#  validates_associated :topic_category_id
  validate :unique_name_within_category

  def recent_threads(user, count)
    read_level = user ? user.forum_level : 0

    self.topic_threads.limit(count).order("topic_threads.id desc").where("topic_threads.is_visible = 1").includes(:topic).where("topics.read_access_level <= #{read_level}")
  end

  def self.visibility(value)
    case value
    when 0 then "everyone"
    when 1 then "any registered user"
    else "a user with a forum level of at least #{value}" 
    end
  end

  def read_visibility
    Topic.visibility(self.read_access_level)
  end
  
  def write_visibility
    Topic.visibility([self.topic_category.write_access_level, self.write_access_level].max)
  end

  def unique_name_within_category
    cnt = Topic.sys(self.system_id).where(:topic_category_id=>self.topic_category_id).where(:name=>self.name).where(["id<>?", self.new_record? ? -1 : self.id]).count
    if cnt > 0
      errors.add(:name, "is not unique within this category")
    end
  end

  def update_url
    self.url = self.name.urlise
  end

  def link
    "/forums/#{self.url}"
  end


end
