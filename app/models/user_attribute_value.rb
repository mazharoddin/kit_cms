class UserAttributeValue < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_attribute

  has_attached_file :asset, :styles=>{:large=>"500x500>", :thumb=>"100x100>", :forum=>"60x60>"}
end
