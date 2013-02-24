class AdUnit < ActiveRecord::Base

 has_many :ad_zones
 attr_accessible :name, :height, :width, :content_type, :system_id

 validates :name, :presence=>true, :uniqueness=>{:scope=>:system_id}
 validates :width, :presence=>true
 validates :height, :presence=>true

 def block_name
   "Ad of size '#{self.name}'"
 end

end
