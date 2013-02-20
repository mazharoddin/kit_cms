class QUser < ActiveRecord::Base

  has_many :q_subscriptions, :dependent => :destroy

end
