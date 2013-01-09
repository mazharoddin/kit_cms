class Admin::GoalsController < AdminController

  def scores
    @goal = Goal.sys(_sid).where(:id=>params[:id]).first
    @scores = @goal.goals_users.includes(:user).page(params[:page]).per(100)

  end

  def index
    @goals = Goal.sys(_sid).all
  end

  def show
    @goal = Goal.find_sys_id(_sid, params[:id])
  end

  def new
    @goal = Goal.new
  end

  def create
    @goal = Goal.new(params[:goal])
    @goal.system_id = _sid
    @goal.user_id = current_user.id

    if @goal.save
      redirect_to [:admin, @goal], :notice => "Successfully created Goal" and return
      logger.debug "x"
    else
      render :action => 'new' 
      logger.debug "y"
    end
  end

  def edit
    @goal = Goal.find_sys_id(_sid,params[:id])
  end

  def update
    @goal = Goal.find_sys_id(_sid,params[:id])
    if @goal.update_attributes(params[:goal])
      redirect_to [:admin, @goal], :notice  => "Successfully updated Goal"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @goal = Goal.find_sys_id(_sid, params[:id])
    @goal.destroy
    redirect_to admin_goals_url, :notice => "Successfully destroyed Goal"
  end
end
