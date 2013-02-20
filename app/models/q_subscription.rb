class QSubscription < ActiveRecord::Base

  belongs_to :q_client
  belongs_to :q_user

end
