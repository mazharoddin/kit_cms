class UserNote < ActiveRecord::Base
  belongs_to :user

  belongs_to :created_by, :class_name=>"User"

  attr_accessor :subject
end
