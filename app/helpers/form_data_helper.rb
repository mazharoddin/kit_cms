module FormDataHelper

  def form_search_structure(search_for, page, per, form_ids = nil, location = nil, distance = 10) 
    ss = search_for.collect { |key,value| key.not_blank? ? "+#{key}:#{value}" : "#{value}" }.join(' ')
    form_search(ss, page, per, form_ids, location, distance)
  end

  def form_search(search_for, page, per, form_ids = nil, location = nil, distance = 10)
    form_ids = Form.pluck(:id) unless form_ids
    form_ids = [form_ids] unless form_ids.is_a?(Array)
    system_id = _sid

      search_size = (params[:per] || "25").to_i
      the_page = (params[:page] || "1").to_i 

      if location.not_blank?
        geo_loc = Geocoder.search(location)
        lat = geo_loc[0].latitude
        lon = geo_loc[0].longitude
      end

      search = Tire.search "gnric_#{app_name.downcase}_form_submissions" do 
        query do
          boolean do 
            must do 
              string search_for
            end
            must do 
              string "form_id:#{form_ids.join(' ')}"
            end
          end
        end
        if location.not_blank?
          filter :geo_distance, :distance=>distance, :location=>"#{lat}, #{lon}"
        end
        filter :term, :system_id=>system_id
        unless @mod
          filter :term, :visible=>1 
        end
        from (the_page-1)*search_size 
        size search_size
      end

      return search.results
  end

  def load_form(id)
    Form.find_sys_id(_sid, id, "title")
  end

  def letter_pagination(base_url, join = ' | ', options = {})
    begin
      output = []
      for index in "A".."Z" do
        output << link_to(index, "#{base_url}#{index}")
      end unless options[:exclude_letters]
      for index in "0".."9" do 
        output << link_to(index, "#{base_url}#{index}") 
      end unless options[:exclude_numbers]

      output.join(join).html_safe
    rescue Exception => e
      e.message
    end
  end

  def show_form_record(id_or_form_submission, options = {})
    if id_or_form_submission.is_a?(FormSubmission)
      sub = id_or_form_submission
    else
      id = id_or_form_submission.to_i
      sub = FormSubmission.sys(_sid).where(:id=>id).first
    end

    return "[record not found '#{id}']" unless sub
    options[:enforce_permissions] = true if options[:enforce_permissions]==nil

    if options[:enforce_permissions]
     unless sub.can_see?(current_user)
       return "<!-- not visible -->".html_safe
      end
    end

    begin
      render partial:"form/record", :locals=>{:record=>sub, :options=>options}
    rescue Exception => e
      e.message
    end
  end

  def form_records(form_id, options = {})
    form = load_form(form_id)
    return "[form not found '#{form_id}']" unless form
   
    begin 
    options[:enforce_permissions] = true if options[:enforce_permissions]==nil && (current_user==nil || !current_user.admin?)
    options[:per_page] ||= 50
    options[:field_conditions] = nil
    options[:only_visible] = true if options[:only_visible]==nil
    options[:user_id] = current_user ? current_user.id : nil
    records = form.records(options).page(params[:page]).per(options[:per_page])

    gnric_render :partial=>"form/records", :locals=>{:records=>records, :form=>form, :options=>options}
    rescue Exception => e
      e.message
    end
  end

  def form_record(id)
    record = FormSubmission.sys(_sid).where(:id=>id).includes([:form_submission_fields, {:form=>[:ungrouped_form_fields, {:form_field_groups=>:form_fields}]}]).first
    return "[record not found]" unless record
    return record
  end

  def format_submission_field(field, options = {})

#    unless options[:noimage]
#      if field.field_type=='image'
#        return image_tag(field.url(:thumb))
#      end
#    end

    if field.field_type=='multicheckbox' || field.field_type=='multiselect'
      return field.value.split('|').join(', ')
    elsif field.field_type=='url' && options[:dont_do_urls]!=true
      return link_to(field.value, field.value)
    else
     return field.value
    end 
  end

  def decode_submission_field(value, field)
    if field.field_type=='multicheckbox'
      return Hash[*value.split('|').collect { |v| [v, true] }.flatten]
    elsif field.field_type=='multiselect'
      return value.split('|')
    else
      return value
    end
  end

  def current_value(submission, field)
    return params[field.code_name.to_sym] if params[field.code_name.to_sym]
    return field.default_value unless submission

    field_submission = submission.form_submission_fields.where(:form_field_id=>field.id).first

    return "" unless field_submission

    return decode_submission_field(field_submission.value, field)
  end
end

