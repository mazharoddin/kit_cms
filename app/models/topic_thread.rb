class TopicThread < KitIndexed

  TopicThread.do_indexing :TopicThread, [
    {:name=>:id, :index=>:not_analyzed, :include_in_all=>false},
    {:name=>:topic_title, :boody=>100, :user=>true},
    {:name=>:title, :boost=>50, :user=>true},
    {:name=>:is_visible, :index=>:not_analyzed},
    {:name=>:moderation_comment, :boost=>10},
    {:name=>:thread_comment, :boost=>10}
  ]

  belongs_to :topic
  has_many :user_thread_views
  has_many :simple_topic_posts, :class_name=>"TopicPost"
  has_many :topic_posts, :order=>"id desc", :dependent=>:destroy
  has_many :topic_posts_rev, :order=>"id", :class_name=>"TopicPost"
  has_many :visible_topic_posts, :conditions=>"is_visible=1", :order=>"updated_at desc", :class_name=>"TopicPost", :foreign_key=>:topic_thread_id

  belongs_to :created_by_user, :foreign_key=>"created_by_user_id", :class_name=>"User"
  belongs_to :last_post_by_user, :foreign_key=>"last_post_by_user_id", :class_name=>"User"

  has_many :thread_views
  has_many :topic_thread_users
  has_many :users, :through=>:topic_thread_users
  has_many :pages, :through=>:page_threads
  has_many :page_threads 

  validates :title, :presence=>true, :length=>{:mininum=>2, :maximum=>250}

  after_create :create_engagement
  attr_accessor :kit_session_id

  def latest_unread(user, forum_user, is_moderator)
    previous_last_post_id = 0
    if user 
      tv = self.thread_views.where(:user_id=>user.id).first
      previous_last_post_id = tv.topic_post_id if tv
    end

    next_post = self.simple_topic_posts
    next_post = next_post.where(:is_visible=>1) unless is_moderator
    next_post = next_post.where("topic_posts.id > #{previous_last_post_id}")
    next_post = next_post.order(:id).first

    if next_post
      next_post_id = next_post.id
    else
      next_post_id = previous_last_post_id
    end
   
    page = page_for_post(previous_last_post_id, forum_user, is_moderator)

    return next_post_id, page
  end

  def page_for_post(post_id, forum_user, is_moderator)
    posts = self.simple_topic_posts
    posts = posts.where(:is_visible=>1) unless is_moderator
    if forum_user.post_order=='asc'
      posts = posts.where("topic_posts.id <= #{post_id}")
    else
      posts = posts.where("topic_posts.id >= #{post_id}")
    end
    page = ((((posts.count-1) / forum_user.posts_per_page).truncate) + 1) rescue 1
    page = 1 if page<1
    return page
  end

  def link_for_post(post_id, forum_user, is_moderator)
    page = page_for_post(post_id, forum_user, is_moderator)
    return self.link + "?page=#{page}##{post_id}"
  end

  def link_latest_unread(user, forum_user, is_moderator)
    if user
      next_post_id, page = latest_unread(user, forum_user, is_moderator)
      return self.link + "?page=#{page}##{next_post_id}"
    else
      return self.link
    end
  end


  def update_post_numbers
    n = 0
    self.topic_posts.each do |post|

      if post.is_visible==1
        n += 1
        l = n
      else
        l = 0
      end

      post.update_attributes(:post_number=>l)
    end
  end

  def create_engagement
    KitEngagement.create(:kit_session_id=>self.kit_session_id, :system_id=>self.system_id, :engage_type=>"Forum Thread", :value=>self.link) if self.kit_session_id
  end


  def link(latest=false)
    "#{topic.link}#{'/latest' if latest}/#{self.id}-#{self.title.urlise}"
  end

  def is_favourited_by(user)
    return false unless user

    return self.topic_thread_users.where(:user_id=>user.id).count > 0 
  end

  def first_post
    self.topic_posts_rev.first
  end

  def self.most_recent(current_user, count, is_mod=false, page=1)
    read_level = current_user ? current_user.forum_level : 0

    TopicThread.limit(count).order("topic_threads.last_post_at desc").where("topic_threads.is_visible = 1").includes(:topic).where("topics.read_access_level <= #{read_level}").page(page).per(count)
  end

  def self.im_on(current_user, count, is_mod=false, page=1) 
    thread_ids = TopicThread.limit(100).order("last_post_at desc").select("distinct topic_threads.id, topic_threads.last_post_at")
    thread_ids = thread_ids.where("topic_posts.is_visible = 1") unless is_mod
    thread_ids = thread_ids.joins(:topic).where("topics.is_visible = 1") unless is_mod
    thread_ids = thread_ids.joins(:topic_posts).where("topic_posts.created_by_user_id = #{current_user.id}").all

    if thread_ids.size>0
      tthreads = TopicThread.where("id in (#{thread_ids.map {|ti| ti.id}.join(",")})")
      tthreads = tthreads.page(page).per(count)
    else
      tthreads = nil
    end

    return tthreads
  end

  def self.threads(count, is_mod = false, page = 1) 
    tthreads = TopicThread.limit(1000).order("last_post_at desc")
    tthreads = tthreads.where(:is_visible=>1) unless is_mod
    tthreads = tthreads.page(page).per(count)
    return tthreads
  end

end
