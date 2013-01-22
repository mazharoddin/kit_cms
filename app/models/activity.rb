class Activity < ActiveRecord::Base

  belongs_to :user

  attr_accessible :system_id, :name, :user_id, :category, :description


  def self.add(sys_id, name, user_or_user_id=0, category='', description='')
    Activity.create(:user_id=>user_or_user_id.is_a?(Integer) ? user_or_user_id : user_or_user_id.id, :system_id=>sys_id, :name=>name, :category=>category, :description=>description).save
  end

end
