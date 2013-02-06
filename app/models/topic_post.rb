class TopicPost < KitIndexed

  TopicPost.do_indexing  :TopicPost, [
    {:name=>:id, :index=>:not_analyzed, :include_in_all=>false},
    {:name=>:system_id, :index=>:not_analyzed, :include_in_all=>false},
    {:name=>:body, :user=>true},
    {:name=>:is_visible, :index=>:not_analyzed},
    {:name=>:moderation_comment},
    {:name=>:created_by_user_display_name}
  ]

  before_save :update_body
  after_create :notify_watchers
  after_create :create_engagement

  has_many :topic_post_edits, :order=>"topic_post_edits.created_at desc"
  has_many :topic_post_votes
  belongs_to :topic_thread
  belongs_to :created_by_user, :foreign_key=>"created_by_user_id", :class_name=>"User"
  
  attr_accessor :title # a pseudo field for when the post is the opening post of a new thread (because a thread has a title)
  attr_accessor :already_voted # an indicator that the current user has already voted on this topic
  attr_accessor :kit_session_id

  def notify_watchers
    self.topic_thread.topic_thread_users.includes({:user=>:forum_user}).where(:email_sent=>nil).where("user_id<>#{self.created_by_user_id}").each do |ttu|
      if ttu.user.forum_user.receive_watch_notifications==1
        Notification.delay.new_post(self, ttu.user)
        ttu.update_attributes(:email_sent=>Time.now)
      end
    end
  end

  def edit_log(separator = "<br/>")
    self.topic_post_edits.map { |edit| "Edited by #{edit.user.display_name} #{edit.created_at.to_s(:short)}" }.join(separator)
  end

  def update_postnumber
    last_post = self.topic_thread.topic_posts.where("topic_posts.id <> #{self.id}").order("post_number desc").first.post_number || 0
    self.post_number = last_post + 1
    self.save
  end

  def create_engagement
    KitEngagement.create(:kit_session_id=>self.kit_session_id, :system_id=>self.system_id, :engage_type=>"Forum Post", :value=>self.link) if self.kit_session_id
  end

  def edited(user)
    TopicPostEdit.create(:raw_body=>self.raw_body, :topic_post_id=>self.id, :user_id=>user.id)
  end

  def update_body
    self.body = self.raw_body.sanitise.friendly_format(:smilies=>Preference.get_cached(self.system_id, "forum_use_smilies")=='true').html_safe
  end
 
  def display_body
    self.body 
  end

  def users_votes(user_id)
    self.topic_post_votes.where(:user_id=>user_id).all
  end

  def TopicPost.delete_all_by_user(sid, user_id, by_user)
    TopicPost.sys(sid).where(:created_by_user_id=>user_id).find_each do |topic|
      topic.mark_as_deleted(by_user, true)
    end 
  end

  def mark_as_deleted(by_user, del)
   self.is_visible = del ? 0 : 1
   self.moderation_comment ||= ''
   self.moderation_comment += (self.is_visible? ? "Undeleted" : "Deleted") + " by #{by_user.email} at #{Time.now}<br/>"
   self.save

   if self.topic_thread.topic_posts.where("is_visible=#{del ? 1 : 0}").count==0
     self.topic_thread.update_attributes(:is_visible=>del ? 0 : 1, :post_count=>self.topic_thread.topic_posts.where("is_visible=1").count)
   else
     self.topic_thread.update_attributes(:post_count =>  self.topic_thread.post_count - (self.is_visible==0 ? 1 : -1))
    end
  end

  def host_link
    "#{Preference.get_cached(self.system_id, "host")}#{self.link}"
  end

  def link # this can be expensive
    "#{self.topic_thread.link}##{self.id}"
  end

end

