class AdZonesAd < ActiveRecord::Base
  
  belongs_to :ad
  belongs_to :ad_zone
end
