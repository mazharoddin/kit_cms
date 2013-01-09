class PageHistory < ActiveRecord::Base

  belongs_to :user, :foreign_key=>"createdby_id"  
  belongs_to :page
  
  def self.record(page,  user_id, activity, details, is_publishable=false, content_id=nil, block_instance_id = nil)
    ph = PageHistory.new
    ph.page = page
    ph.createdby_id = user_id
    ph.activity = activity
    ph.details = details
    ph.is_publishable = is_publishable
    ph.page_content_id = content_id 
    ph.block_instance_id = block_instance_id
    ph.save
  end
  
end
