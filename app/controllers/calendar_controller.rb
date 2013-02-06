class CalendarController < KitController

  before_filter { licensed("calendars") }


  # to handle ticket sales, the item model should include:
  # alter table calendar_entries add sell_tickets tinyint default 0, add tickets_remaining integer default 0, add ticket_price float, add ticket_label varchar(200);
  # it must also have a 'name' field
  def sell_tickets_setup
    redirect_to "/" unless ["CalendarEntry"].include?(params[:item_model])
    item = Kernel.const_get(params[:item_model]).find(params[:item_id])
    redirect_to "/" unless item

    item.sell_tickets = 1 if current_user.admin?
    item.tickets_remaining = params[:quantity]
    item.ticket_price = params[:price]
    item.tax_rate = params[:tax_rate]
    item.seller_id = item.user_id
    item.save

    unless current_user.admin?  
        Notification.moderation_required("Ticket Sales", "Ticket sales set up for #{item.calendar.name}.  View: #{Preference.get_cached(_sid, 'host')}/admin/calendar_entries/#{item.id}", _sid).deliver if params[:item_model]=="CalendarEntry"
    end      
    redirect_to (params[:redirect] || "/") and return
  end

  def buy_tickets
    redirect_to "/" and return unless ["CalendarEntry"].include?(params[:item_model])
    @item = Kernel.const_get(params[:item_model]).find(params[:item_id])
    redirect_to "/" and return unless @item

    @item.tickets_remaining = @item.tickets_remaining - params[:quantity].to_i

    ts = TicketSale.new
    ts.firstname = params[:firstname]
    ts.lastname = params[:lastname]
    ts.email = params[:email]
    ts.unit_price = @item.ticket_price
    ts.tax_rate = @item.tax_rate
    ts.user_id = current_user.id if current_user
    ts.quantity = params[:quantity]
    ts.telephone = params[:telephone]
    @item.ticket_sales << ts
    @item.save 
    redirect_to "#{params[:after_url]}?sale_id=#{ts.id}"
  end

  def sold_as_csv
    redirect_to "/" and return unless ["CalendarEntry"].include?(params[:item_model])
    item = Kernel.const_get(params[:item_model]).find(params[:item_id])
    redirect_to "/" and return unless item

    csv_headers("sold.csv")

    csv_string = CSV.generate do |csv|
      csv << ["id", "reference", "firstname", "lastname", "email", "telephone", "quantity", "price"]
      item.ticket_sales.each do |tick|
        csv << [ tick.id, tick.payment_reference, tick.firstname, tick.lastname, tick.email, tick.telephone, tick.quantity, tick.unit_price]
      end
    end

    render :text=>csv_string
  end

  def update_entry
    unless current_user
      redirect_to "/users/sign_in"
      return
    end

    params[:calendar_entry][:system_id] = _sid
    params[:calendar_entry][:location_attributes][:system_id] = _sid

    @calendar_entry = nil
    if params[:calendar_entry][:id].not_blank?
      if can?(:moderate, :calendar)
        @calendar_entry = CalendarEntry.find_sys_id(_sid, params[:calendar_entry][:id])
        save_okay = @calendar_entry.update_attributes(params[:calendar_entry])
      end
    else
      add_sid(:calendar_entry)
      @calendar_entry = CalendarEntry.new(params[:calendar_entry])
      @calendar_entry.location.address3 = ''
      @calendar_entry.user_id = current_user.id
      save_okay = @calendar_entry.save
    end

    if save_okay
      Activity.add(_sid, "Calendar entry '#{@calendar_entry.name}' on calendar '#{@calendar_entry.calendar.name}'", current_user.id, "Calendar")
      if can?(:moderate, :calendar)
        @calendar_entry.approved_at = Time.now
        @calendar_entry.save
      else
        Notification.moderation_required("Calendar Entry", "New entry made to calendar #{@calendar_entry.calendar.name}.  View: #{Preference.get_cached(_sid, 'host')}/admin/calendar_entries/#{@calendar_entry.id}", _sid).deliver
      end
      url = params[:success] 
      url ||= '/system/sell-tickets' 
      if url.include?('?')
        url += "&"
      else 
        url += "?"
      end
      url += "id=#{@calendar_entry.id}" if @calendar_entry
      redirect_to url and return
    else
      url = params[:edit_url]
      if url =~ /^\/admin\//
        render "/admin/calendar_entries/edit", :layout=>"cms"
      else
        render_page_by_url(params[:edit_url])
      end
    end
  end

end
