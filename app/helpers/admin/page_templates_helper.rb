module Admin::PageTemplatesHelper

  def page_template_asset_selected(asset)
    if @page_template && @page_template.id!=nil
      @page_template.html_assets.include?(asset)
    else
      false
    end
  end
  
  def show_html_assets(list, type)
    return '' unless list
    o = ''
    list.split(',').each do |s|
      ss = HtmlAsset.sys(_sid).where(:file_type=>type).where('lower(name) = "' + s.downcase.strip + '"').first
      if ss
        o += "<a href='/admin/html_asset/#{ss.id}'>#{ss.name}</a>"
      else
        o += s
      end
      o += ' '
    end
    return o.html_safe
  end
end
