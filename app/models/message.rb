class Message < ActiveRecord::Base

  def display_message
    self.updated_at.strftime("%H:%M:%S") + " - " + self.message
  end
end
