class Admin::CalendarEntriesController < AdminController

  before_filter { licensed('calendars') }
  
  layout "cms"

  def sold
    @calendar_entry = CalendarEntry.where(:id=>params[:id]).sys(_sid).first
  end

  def index
    @calendar_entries = CalendarEntry.order(:approved_at).sys(_sid)
    @calendar_entries = @calendar_entries.where("approved_at is not null") if params[:approved]
    @calendar_entries = @calendar_entries.where("approved_at is null") if params[:unapproved]
    @calendar_entries = @calendar_entries.where(:calendar_id=>params[:calendar_id]) if params[:calendar_id]
    @calendar_entries = @calendar_entries.page(params[:page]).per(50)
  end

  def show
    @calendar_entry = CalendarEntry.sys(_sid).where(:id=>params[:id]).first
    redirect_to "/db", :notice=>"Can't find calendar entry" and return unless @calendar_entry
    if request.post?
      if params[:approve]
        @calendar_entry.update_attributes(:approved_at => Time.now)
      end
    end
  end

  def new
  end

  def create
    params[:calendar_entry][:system_id] = _sid
    @calendar_entry = CalendarEntry.new(params[:calendar_entry])
    @calendar_entry.location.address3 = ''
    @calendar_entry.user = current_user

    if @calendar_entry.save
      redirect_to [:admin, @calendar_entry], :notice => "Successfully created calendar entry"
    else
      render :action => 'new'
    end
  end

  def edit
    @calendar_entry = CalendarEntry.find_sys_id(_sid,params[:id])
  end

  def update
    @calendar_entry = CalendarEntry.find_sys_id(_sid, params[:id])
    if @calendar_entry.update_attributes(params[:calendar_entry])
      redirect_to [:admin, @calendar_entry], :notice  => "Successfully updated calendar entry"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @calendar_entry = CalendarEntry.find_sys_id(_sid, params[:id])
    @calendar_entry.destroy
    redirect_to "/admin/calendars", :notice => "Successfully deleted calendar entry"
  end
end
