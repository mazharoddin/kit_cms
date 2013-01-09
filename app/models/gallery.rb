class Gallery < ActiveRecord::Base
  belongs_to :created_by, :foreign_key=>"created_by_id", :class_name=>"User"

  has_many :gallery_assets, :order=>:display_order
  has_many :assets, :through=>:gallery_assets


end
