module CalendarHelper

  def module_gnric_list_tickets(item, options={})
    begin
    gnric_render :partial=>"calendar/list_tickets", :locals=>{:item=>item, :options=>options}
    rescue Exception => e
      e.message
    end
  end

  def module_gnric_buy_tickets(item, options = {})
    begin
    event = CalendarEntry.sys(_sid).where(:id=>item).first

    options[:min_quantity] ||= 1
    options[:max_quantity] ||= 10

    if options[:max_quantity] > event.tickets_remaining
      options[:max_quantity] = events.tickets_remaining
      options[:show_ticket_warning] = true
    else
      options[:show_ticket_warning] = false
    end

    gnric_render :partial=>"calendar/buy_tickets", :locals=>{:item=>item, :options=>options}
    rescue Exception => e
      e.message
    end
  end

  def module_gnric_ticket_form(model, description, options = {})
  
   options[:submit] ||= "Submit"
   options[:redirect] ||= "/"
   options[:label] ||= 'Tickets'
   begin
     gnric_render :partial=>"calendar/sell_tickets", :locals=>{:description=>description, :options=>options,  :model=>model}
    rescue Exception => e
      e.message
    end
  end

  def module_gnric_calendar_entry_add(calendar_id, options = {})

    unless calendar_id.is_number?
      calendar_id = Calendar.find_by_name(calendar_id).id
    end

    options[:success] ||= "/"
    options[:edit_url] ||= params[:edit_url] || request.fullpath

    calendar_entry = @calendar_entry

    unless calendar_entry 
      calendar_entry = CalendarEntry.new
      calendar_entry.calendar_id = calendar_id
      calendar_entry.location = Location.new
      calendar_entry.location.country = "United Kingdom"
    end

    gnric_render :partial=>"calendar/form", :locals=>{:calendar_entry=>calendar_entry, :choose_calendar=>false, :options=>options}
  end

  def module_gnric_calendar_entry_load(id)
    entry = CalendarEntry.sys(_sid).where(:id=>id).first
    entry = nil if entry && entry.approved_at == nil && !can?(:moderate, :calendar)
    return entry
  end

  def module_gnric_calendar_entry(id, options)
    entry = CalendarEntry.sys(_sid).where(:id=>id).first
    if entry
      entry = nil if entry.approved_at == nil && !can?(:moderate, :calendar)
      gnric_render :partial=>"calendar/calendar_entry", :locals=>{:entry=>entry, :options=>options}
    else
      if params[:edit]=="1"
        "[Calendar entry will appear here]"
      else
        "[Calendar entry #{params[:id]} not found]"
      end
    end
  end

  def module_gnric_calendar(calendar_id, options = {})

    begin
    year = options[:year]
    month = options[:month]

    mini = options[:mini]==true

    unless options.include?(:show_filters)
      options[:show_filters] = ! mini
      options[:show_days] = !mini
    end    
    options[:show_header] = true unless options.include?(:show_header)
    filter = options[:filter] || ''
    year ||= Time.now.year 
    month ||= Time.now.month

    month = params[:month].to_i if params[:month]
    year = params[:year].to_i if params[:year]

    params[:srid] = '' if params[:srid]=='0'
    params[:etid] = '' if params[:etid]=='0'

    filter = "(1=1) " if filter == ''
    if params[:subregion].not_blank? && params[:search_area]
      filter += " and subregions.name = \"#{params[:subregion]}\""
    end
    if params[:srid].not_blank? && params[:search_area]
      filter += " and locations.subregion_id = #{params[:srid]}"
    end
    if params[:entrytype].not_blank?
      filter += " and calendar_entry_types.name = \"#{params[:entrytype]}\""
    end
    if params[:etid].not_blank?
      filter += " and calendar_entries.calendar_entry_type_id = #{params[:etid]}"
    end

    unless can?(:moderate, :calendar)
      filter += " and calendar_entries.approved_at is not null "
    end

    date = Time.new(year, month, 1, 0, 0, 0, 0)
    cal = Calendar.find_by_name_or_id(calendar_id)
    return "[can't find calendar '#{calendar_id}']" unless cal

    entries = {}
    days_in_this_month = days_in_month(month)

    for i in 1..days_in_this_month do
      entries[i] = []
    end
    start_date = date
    end_date = Time.new(year,month,days_in_this_month, 23, 59, 0, 0)

    position = nil
    if params[:postcode] && params[:search_postcode]
      position = Geocoder.coordinates(params[:postcode]) 
      if params[:distance]
        distance = params[:distance].to_i
      end
    end

    cal.entries_between(start_date, end_date, filter, position, distance).each do |entry|
      for day in entry.start_date..entry.end_date
        next unless day.month == month
        if entry.no_days || (entry.on_day(day.wday)==1)
          entries[day.day] << entry
        end
      end
    end  
    gnric_render :partial=>"calendar/month", :locals=>{:calendar=>cal, :date=>date, :entries=>entries, :options=>options, :position=>position}

    rescue Exception => e
      logger.debug e
      logger.debug e.backtrace.join('\n')
      return "[cannot display calendar]"
    end
  end

  def days_in_month(d)
    (Date.new(d.year, 12, 31) << (12-d.month)).day
  end

  def regions_list
    last_region_id = nil 
    first = true
    op = "{ "
    Subregion.order("regions.name, subregions.name").includes(:region).each do |sr| 
      if sr.region_id != last_region_id 
        if !first
          op += "],\r\n"
        else 
          first = false
        end 
        last_region_id = sr.region_id
        op += "#{sr.region_id} : ["
      end
      op += "[ \"#{sr.name}\", #{sr.id} ], "
    end
    op += "]}"

    return op.html_safe
  end


  
end
