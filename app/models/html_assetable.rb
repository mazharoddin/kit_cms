class HtmlAssetable < ActiveRecord::Base
  belongs_to :html_asset
  belongs_to :html_assetable, :polymorphic=>true
end
