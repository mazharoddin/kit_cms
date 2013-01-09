class PageAutoSave < ActiveRecord::Base
  belongs_to :page_url
  belongs_to :user
  
end
