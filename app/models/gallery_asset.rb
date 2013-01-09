class GalleryAsset < ActiveRecord::Base
  belongs_to :gallery
  belongs_to :asset
end
