class Role < ActiveRecord::Base
  attr_accessible :system_id, :name
  has_and_belongs_to_many :users
end
