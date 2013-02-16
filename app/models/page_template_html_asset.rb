class PageTemplateHtmlAsset < ActiveRecord::Base
  belongs_to :html_asset
  belongs_to :page_template
end
