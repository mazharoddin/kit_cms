class TopicThreadUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic_thread

  has_one :forum_user
end

