class Admin::BlockController < AdminController

  layout "cms-boxed"

  def index
    @blocks = Block
                .includes(:user)
                .order("created_at desc")
    @blocks = @blocks.where('name like "%' + params[:for] + '%" or body like "%' + params[:for] + '%" or description like "%' + params[:for] + '%"') if params[:for].not_blank?
    @blocks = @blocks.page(params[:page]).per(3)
  end

  def new
    @block ||= Block.new
  end

  def show
    @block = Block.find_sys_id(_sid, params[:id])
    if params[:version]
      ver = params[:version].to_i
      for v in 0..ver
        @block.revert_to(v)
      end
    end
  end

  def destroy
    @block = Block.find_sys_id(_sid, params[:id])
    Activity.add(_sid, "Deleted block '#{@block.name}'", current_user.id, "Block")
    Block.delete_all("id = #{params[:id]} and system_id = #{_sid}")
    flash[:warn] = "Block deleted"
    redirect_to "/admin/block"
  end

  def update
    params[:block][:page_template_ids] ||= []
    @block = Block.find_sys_id(_sid, params[:id])
    @block.user_id = current_user.id

    @block.update_attributes(params[:block])
    if @block.save
      Activity.add(_sid, "Update block '#{@block.name}'", current_user.id, "Block")

      redirect_to "/admin/block/#{@block.id}"
      return
    else
      render "edit"
    end
  end

  def edit
    @block = Block.find(params[:id])
  end

  def create
    @block = Block.new(params[:block])
    @block.user_id = current_user.id
    if @block.save
      Activity.add(_sid, "Create block '#{@block.name}'", current_user.id, "Block")
      redirect_to "/admin/block/#{@block.id}"
      return
    else
      render "new"
    end
  end

end
