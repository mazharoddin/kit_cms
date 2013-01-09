class ThreadView < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic_thread
  belongs_to :topic_post

end
