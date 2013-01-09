class PageThread < ActiveRecord::Base
  belongs_to :page
  belongs_to :topic_thread
end
