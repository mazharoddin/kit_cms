class Admin::CalendarsController < AdminController
  before_filter :licensed
  
  layout "cms-boxed"


  def index
    @calendars = Calendar.all
  end

  def show
    @calendar = Calendar.find_sys_id(_sid, params[:id])
  end

  def new
    @calendar = Calendar.new
  end

  def create
    add_sid(:calendar)
    @calendar = Calendar.new(params[:calendar])
    @calendar.user = current_user
    if @calendar.save
      Activity.add(_sid, "Created calendar '#{@calendar.name}'", current_user.id, "Calendar")
      redirect_to [:admin, @calendar], :notice => "Successfully created Calendar"
    else
      render :action => 'new'
    end
  end

  def edit
    @calendar = Calendar.find_sys_id(_sid, params[:id])
  end

  def update
    add_sid(:calendar)
    @calendar = Calendar.find_sys_id(_sid, params[:id])
    if @calendar.update_attributes(params[:calendar])
      Activity.add(_sid, "Updated calendar '#{@calendar.name}'", current_user.id, "Calendar")
      redirect_to [:admin, @calendar], :notice  => "Successfully updated Calendar"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @calendar = Calendar.find_sys_id(_sid,params[:id])
    Activity.add(_sid, "Deleted calendar '#{@calendar.name}'", current_user.id, "Calendar")
    @calendar.destroy
    redirect_to admin_calendars_url, :notice => "Successfully deleted Calendar"
  end
end
