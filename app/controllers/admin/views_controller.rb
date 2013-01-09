class Admin::ViewsController < AdminController
  layout 'cms-boxed'

  def index
    @views = View.sys(_sid).all
  end

  def show
    @view = View.find_sys_id(_sid, params[:id])
  end

  def new
    @view = View.new
  end

  def create
    add_sid(:view)
    @view = View.new(params[:view])
    if @view.save
      redirect_to [:admin, @view], :notice => "Successfully created view."
    else
      render :action => 'new'
    end
  end

  def edit
    @view = View.find_sys_id(_sid, params[:id])
  end

  def update
    @view = View.find_sys_id(_sid, params[:id])
    if @view.update_attributes(params[:view])
      redirect_to [:admin, @view], :notice  => "Successfully updated view."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @view = View.find_sys_id(_sid, params[:id])
    @view.destroy
    redirect_to admin_views_url, :notice => "Successfully destroyed view."
  end
end
