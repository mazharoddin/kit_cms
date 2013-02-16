class HtmlAssetUsage < ActiveRecord::Base
  belongs_to :html_assetable, :polymorphic => true
end
