class Admin::BlocksController < AdminController
  layout "cms"
  
  def index
    logger.debug "*****************************************" * 5
    @blocks = Block.sys(_sid).order(:name)
    @blocks = @blocks.where('name like "%' + params[:for] + '%" or body like "%' + params[:for] + '%" or description like "%' + params[:for] + '%"') if params[:for].not_blank?
    @blocks = @blocks.page(params[:page]).per(25)
  end

  def show
    @block = Block.find_sys_id(_sid,params[:id])
  end


  def new
    @block = Block.new
  end

  def create
    params[:block][:system_id] = _sid
    @block = Block.new(params[:block])
    @block.user_id = current_user.id
    if @block.save
      redirect_to [:admin, @block], :notice => "Successfully created block"
    else
      render :action => 'new'
    end
  end

  def edit
    @block = Block.find_sys_id(_sid,params[:id])
  end

  def update
    @block = Block.find_sys_id(_sid,params[:id])
    @block.user_id = current_user.id

    if @block.update_attributes(params[:block])
      Activity.add(_sid, "Update block '#{@block.name}'", current_user.id, "Block")

      if params[:submit_button]=="save-and-edit-again"
        redirect_to "/admin/blocks/#{@block.id}/edit#editor"
      else
        redirect_to "/admin/blocks/#{@block.id}"
      end
      
      return
    else
      render :action => 'edit'
    end
  end

  def destroy
    Activity.add(_sid, "Deleted block '#{@block.name}'", current_user.id, "Block")
    @block = Block.find_sys_id(_sid, params[:id])
    @block.destroy
    redirect_to admin_blocks_url, :notice => "Successfully destroyed block"
  end
end
