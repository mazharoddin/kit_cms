class TopicPostEdit < ActiveRecord::Base

  belongs_to :user
  belongs_to :topic_post

end

