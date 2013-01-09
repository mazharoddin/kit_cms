class UserThreadView < ActiveRecord::Base
  belongs_to :topic_thread
  belongs_to :user

  def self.record(user, post)
    return unless user
    UserThreadView.connection.execute("replace into user_thread_views (system_id, topic_thread_id, user_id, seen_post_id) values (#{post.system_id}, #{post.topic_thread_id}, #{user.id}, #{post.id});")
  end
end
