class Opponent < ActiveRecord::Base
  belongs_to :user
  belongs_to :game

  def display_name
    self.user.display_name
  end


end
