class Admin::GroupController < AdminController

  before_filter { licensed("groups") }

  def index
    @group = Group.new
    @groups = Group.order(:name).sys(_sid).all
  end

  def create
    @group = Group.new(params[:group])
    @group.system_id = _sid 
    if @group.save
      flash[:notice] = "Group created"
      Activity.add(_sid, "Created group '#{@group.name}'", current_user.id, "Groups", '') 
      redirect_to "/admin/groups"
    else
      @groups = Group.sys(_sid).order(:name).all
      render "index"
    end
  end

  def destroy
    @group = Group.find_sys_id(_sid, params[:id])
    Group.destroy(params[:id])
    Activity.add(_sid, "Deleted group '#{@group.name}'", current_user.id, "Groups", '') 
    flash[:notice] = "Group deleted"
    redirect_to "/admin/groups"
  end
end
