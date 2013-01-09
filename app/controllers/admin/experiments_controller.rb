class Admin::ExperimentsController < AdminController

  before_filter { licensed("experiments") }

  def index
    @experiments = Experiment.sys(_sid).all
  end

  def show
    @experiment = Experiment.sys(_sid).where(:id=>params[:id]).includes([:user, :goal]).first
  end

  def new
    @experiment = Experiment.new
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    @experiment.system_id = _sid
    @experiment.user_id = current_user.id
    if @experiment.save
      redirect_to [:admin, @experiment], :notice => "Successfully created Experiment"
    else
      render :action => 'new'
    end
  end

  def edit
    @experiment = Experiment.find_sys_id(_sid, params[:id])
  end

  def update
    @experiment = Experiment.find_sys_id(_sid, params[:id])
    if @experiment.update_attributes(params[:experiment])
      redirect_to [:admin, @experiment], :notice  => "Successfully updated Experiment"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @experiment = Experiment.find_sys_id(_sid, params[:id])
    @experiment.destroy
    redirect_to admin_experiments_url, :notice => "Successfully destroyed Experiment"
  end
end
