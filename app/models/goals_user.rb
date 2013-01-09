class GoalsUser < ActiveRecord::Base
  # attr_accessible :title, :body
  #
  belongs_to :user
  belongs_to :goal

  after_create :create_engagement
  attr_accessor :kit_session_id
  attr_accessor :system_id

  def create_engagement
    KitEngagement.create(:kit_session_id=>self.kit_session_id, :system_id=>self.system_id, :engage_type=>"Goal: #{self.goal.name}", :value=>"") if self.kit_session_id
  end

end
