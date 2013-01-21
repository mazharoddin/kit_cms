class Admin::MappingController < AdminController

  layout "cms"

  def index
    @mappings = Mapping.sys(_sid).where(:hidden=>0).order(:source_url).page(params[:page]).per(20)
  end

  def new
    @mapping ||= Mapping.new
    @mapping.is_active = 1
    @mapping.status_code = "301"
    @mapping.is_asset = 1 if params[:target]
    @mapping.target_url = params[:target]
  end

  def destroy
    Mapping.delete(params[:id])
    flash[:warn] = "Mapping deleted"
    redirect_to "/admin/mapping"
  end

  def update
    @mapping = Mapping.find_sys_id(_sid, params[:id])

    @mapping.update_attributes(params[:mapping])
    if @mapping.save
      redirect_to "/admin/mapping"
      return
    else
      render "edit"
    end
  end

  def edit
    @mapping = Mapping.find_sys_id(_sid, params[:id])
  end

  def create
    @mapping = Mapping.new(params[:mapping])
    @mapping.system_id = _sid
    @mapping.user_id = current_user.id
    @mapping.params_url ||= ""
    @mapping.is_page = 0 if @mapping.is_asset?
    if @mapping.save
      redirect_to "/admin/mapping"
      return
    else
      render "new"
    end
  end
  
end
