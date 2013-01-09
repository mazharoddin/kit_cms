class Activity < ActiveRecord::Base

  belongs_to :user

  def self.add(sys_id, name, user_id=0, category='', description='')
    Activity.create(:user_id=>user_id, :system_id=>sys_id, :name=>name, :category=>category, :description=>description).save
  end

end
