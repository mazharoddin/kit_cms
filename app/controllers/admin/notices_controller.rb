class Admin::NoticesController < AdminController
  def index
    @notices = Notice.sys(_sid).all
  end

  def show
    @notice = Notice.find_sys_id(_sid, params[:id])
  end

  def new
    @notice = Notice.new
  end

  def create
    @notice = Notice.new(params[:notice])
    @notice.system_id = _sid
    if @notice.save
      redirect_to [:admin, @notice], :notice => "Successfully created Notice"
    else
      render :action => 'new'
    end
  end

  def edit
    @notice = Notice.find_sys_id(_sid, params[:id])
  end

  def update
    @notice = Notice.find_sys_id(_sid, params[:id])
    if @notice.update_attributes(params[:notice])
      redirect_to [:admin, @notice], :notice  => "Successfully updated Notice"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @notice = Notice.find_sys_id(_sid, params[:id])
    @notice.destroy
    redirect_to admin_notices_url, :notice => "Successfully deleted Notice"
  end
end
