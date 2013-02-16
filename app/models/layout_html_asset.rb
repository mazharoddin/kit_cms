class LayoutHtmlAsset < ActiveRecord::Base
  belongs_to :html_asset
  belongs_to :layout
end

