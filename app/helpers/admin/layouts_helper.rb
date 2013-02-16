module Admin::LayoutsHelper

  def layout_asset_selected(asset)
    if @layout && @layout.id!=nil
      @layout.html_assets.include?(asset)
    else
      false
    end
  end
end
