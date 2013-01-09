class PostReport < ActiveRecord::Base
  belongs_to :topic_post
  belongs_to :user
end
