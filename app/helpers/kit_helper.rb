module KitHelper

  require 'digest/md5'
  # kit_calendar - see calendar_helper

  def app_name
    Preference.get_cached(_sid, "app_name")
  end

  def form_check_code
    check = "#{rand(1000000).to_s}.#{Time.now}"

    hidden_field_tag :check, Digest::MD5.hexdigest(check)
  end

  def doc_ready(s=nil)
  "<script type='text/javascript'>
    $(document).ready(function() {
      #{s if s}
      #{yield if block_given?}
    });
  </script>".html_safe
  end

  def edit_link
   
    op = "$(\""

    op += "<div id=\'edit_status\'><a href=\'/db\'>Dashboard</a>"
   
    if @page
     op += " | <a id='info_link' href=\'/page/#{@page.id}/info\'>Info</a> "
     op += "| <a href=\'#{request.fullpath}?edit=1\'>Edit</a>" unless @page.locked?
      el = op
    end
    op += "</div>\").appendTo('body');\n"

    if @page
      op += "$('#edit_status').addClass(\"#{@page.status_id==Page.published_status(_sid) ? 'published' : 'not_published'}\");\n"
      op += "$('#edit_status #info_link').addClass('deleted');" if @page.is_deleted==1
    end

    op.html_safe
  end    


  def current_path_with_new_params(params)
    "#{current_without_params}?#{params}"
  end

  def current_without_params
    request.fullpath.split("?")[0]
  end

  def kit_javascripts(additional = [])
    op = []
    (additional + javascripts).each do |name|
      next if name.is_blank?
      js = HtmlAsset.fetch(_sid, name.downcase.strip, "js")
      if js
        op << "<script type='text/javascript' src='/kit/js/#{js.kit_name.downcase}'></script>"
      else
        op << "<!-- javascript missing '#{name.downcase.strip}' -->"
      end
    end
    op.join("\n").html_safe
  end

  def javascripts
    if @page
      (@page.page_template.layout.javascripts + "," + @page.page_template.javascripts).split(',').uniq rescue []
    else
      js = []
      layout_name = controller.layout_name_being_used rescue "application"
      if layout_name.not_blank?
        layout = Layout.sys(_sid).where(:name=>layout_name).first
        if layout
          js += layout.javascripts.split(',').uniq
        end
      end
      begin
      if controller.template_being_used
        js += controller.template_being_used.javascripts.split(',').uniq 
      end
      rescue 
        logger.debug "Javascripts error"
      end

      return js
    end
  end

  def kit_stylesheets(additional = [])
    op = []
    begin
    s = stylesheets 
    rescue Exception => e
      s = ['application'] 
      logger.debug "#{e.message}"
    end
    (additional + s).each do |name|
      next if name.is_blank?
      sheet = HtmlAsset.fetch(_sid, name.downcase.strip, "css")
      if sheet
        op << "<link rel='stylesheet' type='text/css' href='/kit/css/#{sheet.kit_name.downcase}'>"
      else
        op << "<!-- stylesheet missing '#{name.downcase.strip}' -->"
      end
    end
    op.join("\n").html_safe
  end


  def host_name
    h = Preference.getCached(_sid, 'host')
    h ||= request.domain

    if h =~ /^https?:\/\/(.*)$/
      return $1.strip.downcase
    else
      return h.strip.downcase
    end
  end

  def kit_pagination(model)
    r = '<div class="kit_pagination">'
    r += " <div class='page_info'>
        Showing #{[model.per_page, model.total_entries].min} of #{model.total_entries} 
      </div>"  unless model.instance_of?(ActiveRecord::Relation)
      r += paginate model
      r += "</div>"
      r.html_safe
  end

  def kit_submit(label, options = {})
    options[:class] ||= ''
    options[:class] += " action"
    trans_name = label.urlise
    options[:id] ||= "submit[#{trans_name}]"
    options[:name] ||= trans_name
    options["data-value"] = trans_name
    link_to_function label, "submit_form(this)", options
  end

  def cm_editor(mode, object, field, form, form_field = nil)
    form_field ||= "#{object}_#{field}"
  
    mode = 'htmlmixed' if mode == 'html'
    mode = 'css' if mode == 'sass' || mode == 'scss'
    render :partial=>'utility/cm_editor', :locals=>{:mode=>mode, :field=>field, :form_field=>form_field, :form=>form}
  end

  def hide_if(bool)
    bool ? "display:none;" : ""
  end

  def hide_unless(bool)
    hide_if(!bool)
  end

  def icon_to_show(label, element, options = {}) 
    id = "link_to_show_#{element}_#{rand(10000000)}"
    options[:id] ||= id
    return icon_to_function label, "$('##{options[:id]}').hide(); $('##{element}').slideDown();", false, options
  end

  def field_reveal(data, length)
    return "" unless data
    if data.length <= length
      return data
    end
    key = data.md5  + rand(10000000).to_s
    s = "<div style='display: inline;' id='#{key}'>"
    s += "<div style='display: inline;' class='short'>"
    s += truncate(data, :length=>length, :omission=>'')
    s += "... "
    s += link_to_function "More", "field_show_more('#{key}');", :class=>'field_show_more'
    s += "</div><div style='display: none;' class='long'>"
    s += data
    s += " "
    s += link_to_function "Less", "field_hide_more('#{key}');", :class=>'field_show_more'
    s += "</div></div>"
    return s.html_safe
  end

  def page_meta
    if @page
      render :partial=>"pages/meta"
    else
      ""
    end
  end

  def selected_item(name)
    if request.fullpath =~ /#{name}/
      "class='selected'"
    else 
      ""
    end
  end

  def selected_class(name)
    if request.fullpath =~ /#{name}/
      "'selected'"
    else 
      ""
    end
  end

  def wrapper_class
    @background_class
  end

  def page_title
    if @page_title
      return @page_title
    elsif @page && @page.respond_to?(:title)
      return @page.title
    elsif self.respond_to?(:title)
      return self.title
    else
      Preference.getCached(_sid, "site_name")
    end
  end

  def style_word(word) 
    letter = word[0]
    rest = word[1..word.length]
    "<span class='letter #{letter}'>#{rest}</span>".html_safe
  end


  def logo
    render :partial=>"admin/shared/name"
  end

  def page_edit_path(page)
    "/page/#{page.id}?edit=1"
  end

  def page_edit_draft_path(page)
    page_edit_path + "&draft=1"
  end

  def page_draft(page)
    "/page/#{page.id}?draft=1"
  end

  def button_to_with_params(label, url, data = {})
    render :partial=>"utility/button_to_with_params", :locals=>{:url=>url, :data=>data, :button_label=>label} 
  end

  def friendly_page_path(path)
    "/#{page.class.name.tableize.pluralize}/#{page.name}"
  end

  def version_page_path(page, version)
    "/#{page.class.name.tableize.pluralize}/#{page.id}?v=#{version}"
  end

  def is_admin?
    return current_user && current_user.superadmin?
  end

  def debug?
    is_debug?
  end

  def is_debug?
    return Preference.getCached(_sid, "no_debug") != "true"
  end

#  def template_snippet(id)
#    page_snippet = PageSnippet.where(:instance_id=>id).first
#    render :inline=>page_snippet.render
#  end

  def snippet(page_snippet_id, snippet_id, defaults = {}) 
    render_snippet(@page, page_snippet_id, snippet_id, defaults)
  end

  def render_snippet(page, page_snippet_id, snippet_id, defaults)
    page_snippet = page.page_snippets.where(:instance_id=>"snippet_#{page_snippet_id}").first

    unless page_snippet
      return "[Snippet missing #{snippet_id}]"
    end

    snippet = Snippet.find_by_name_or_id(snippet_id)
    field_id = "snippet_#{page_snippet_id}"

    r = %?
    <div class='mercury-region' data-type='snippetable' data-fieldid='snippet_#{page_snippet_id}' data-field='snippet_#{page_snippet_id}' id='snippet_#{page_snippet_id}'><div class="mercury-snippet" data-snippet="snippet_#{page_snippet_id}">#{render :inline=>page_snippet.render}</div></div>
    ?.html_safe

    return r
  end

  def optional_field(name)
    field(name, 'text', nil, true, 'div', true)
  end


  def field(name, type = 'text', title = nil, is_template = true, wrapper = 'div', hide_if_empty = false)
    return '' unless @page
    if @page.respond_to?(name) 
      return "<span id='page_#{name}'>#{@page.send(name)}</span>".html_safe
    end

    value = @page.render_field(name, @page.draft ? -1 : 0)

    if @page.editable
      r = nil
      title ||= name.titleize

      if value==nil
        value = "[---#{title}---]" 
        is_template = false
      end

      return ("<#{wrapper} class='mercury-region' data-type='#{Page.mercury_region(type)}' data-fieldid='#{name}' data-field='#{title}' id='#{name}'>" + 
             (is_template ? (render :inline=>value, :handler=>:erb) : value) + 
             "</#{wrapper}>").html_safe
    else
      if hide_if_empty && value!=nil && value.starts_with?("[---") && value.ends_with?("---]")
        return ""
      else
        return (is_template ? render(:inline=>value) : value).html_safe rescue ""
      end
    end
  end

  def icon_to(text, link, icon = false, options = nil) 
    icon_link(false, text, link, icon, options)
  end

  def icon_to_function(text, fnction, icon = false, options = nil) 
    icon_link(true, text, fnction, icon, options)
  end  

  def icon_link(is_function, text, link, icon = false, toptions = nil)
    icon = 'no' if icon==false
    options = { :class => '' }
    options.merge! toptions if toptions
    options[:class] += " icon #{icon + '_icon'}"

    if is_function
      link_to_function text, link, options
    else
      link_to text, link, options
    end
  end

  def bold_if(text, bold=true)
    if bold
      return "<b>#{text}</b>".html_safe
    else
      return text
    end
  end

  def pref(name, system = false, default = nil)
    return nil unless current_user || system
    p = Preference.getCached(_sid, name, system ? nil : current_user.id)
    return p ? p : default
  end

  def sys_pref(name)
    pref(name, true)
  end

  def _sid
    @kit_system.get_system_id
  end

  def kit_default_header
    kit_render :partial=>"layouts/kit_header"
  end

  def feature?(name)
    Preference.licensed?(_sid, name)
  end

  def current_url(patterns)
    # pattern something like /static/:param1/:param2
    rs = request.fullpath.split('/')
    rs.delete_at(0)

    pss = rs.last.split('?')
    p = {}
    if pss && pss[1]
      pss[1].split('&').each do |pair|
        k,v = pair.split('=')
        p[k] = v
      end

      rs[rs.length-1] = pss[0]
    end
    return nil unless rs
    patterns = [patterns] if patterns.instance_of?(String)
    patterns.each do |pattern|
      ps = pattern.split('/')
      ps.delete_at(0)
      next unless ps.length==rs.length
      result = p.clone
      match = true
      for i in 0..ps.length-1 do
        if ps[i][0].chr==':'
          key = ps[i][1..200].to_sym
          result[key] = rs[i]      
        else
          if ps[i] != rs[i]
            match = false
            break
          end
        end
      end
      if match 
        result[:matched] = pattern
        return result 
      end
    end
    return nil

  end

  def pounds(n)
    number_to_currency(n, :unit=>"&pound;")
  end

  def field_values(field_name, page_template_ids = nil, only_published_and_visible = true, version = 0) 
    Page.field_values(_sid, field_name, page_template_ids, only_published_and_visible)
  end

  def pages_field_matches(field_name, field_value,  page_template_ids = nil, only_published_and_visible = true, version = 0) 
    Page.field_matches(_sid, field_name, field_value,  page_template_ids = nil, only_published_and_visible = true, version = 0) 
  end

  def kit_render(options = {})
    custom_template = PageTemplate.get_custom_template(_sid, options[:partial], request, true)
    if custom_template
      options[:type] = custom_template.template_type || 'erb'
      options[:inline] = custom_template.body
      options.delete(:partial)
      render options
    else
      render options
    end
  end

  def strike_if(content, strike)
    "<span style=\"#{'text-decoration: line-through;' if strike}\">#{content}</span>".html_safe
  end

  def js_form_validation(form_selector)
    doc_ready("$('#{form_selector}').validate();")
  end

  def date_picker(selector, options = {})
    options[:date_format] = "dd/mm/yy"
    doc_ready("$('#{selector}').datetimepicker({ showOn: 'both', dateFormat: '#{options[:date_format]}'});")
  end    

  def format_date(date)
    date.strftime(Preference.getCached(_sid, 'date_time_format') || '%d-%b-%y %H:%M')
  end    

   def obscure_email(email)
        return nil if email.nil? #Don't bother if the parameter is nil.
        lower = ('a'..'z').to_a
        upper = ('A'..'Z').to_a
        email.split('').map { |char|
            output = lower.index(char) + 97 if lower.include?(char)
            output = upper.index(char) + 65 if upper.include?(char)
            output ? "&##{output};" : (char == '@' ? '&#0064;' : char)
        }.join
    end

end


