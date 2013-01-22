class Mapping < ActiveRecord::Base
  attr_accessible :source_url, :target_url, :is_asset, :user_id, :status_code, :is_active, :params_url, :is_page, :system_id, :is_asset, :hidden
  belongs_to :user
end
