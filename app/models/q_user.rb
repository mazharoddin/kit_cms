class QUser < ActiveRecord::Base

  has_one :q_client
  has_many :q_subscriptions, :dependent => :destroy

  def display_notification
    return self.twitter_handle if self.notification_method=='twitter'
    return self.email
  end

end
