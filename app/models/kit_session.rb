class KitSession < ActiveRecord::Base
  attr_accessible :session_id, :user_id, :first_request, :last_request, :page_views, :system_id
  #
  belongs_to :user
end
