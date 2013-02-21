class QSent < ActiveRecord::Base
  belongs_to :q_client
  belongs_to :q_user
  belongs_to :q_event
  belongs_to :q_subscription
end
