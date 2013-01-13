class UserLink < ActiveRecord::Base
  attr_accessible :user_id, :label, :url

  belongs_to :user

end
