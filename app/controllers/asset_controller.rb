class AssetController < AdminController
  layout "cms-boxed"


  def update
    @asset = Asset.find_sys_id(_sid, params[:id])
    if @asset.update_attributes(params[:asset])
      if params[:asset][:file]
        asset = Asset.find_sys_id(_sid, params[:id])
        asset.file_file_name = params[:asset][:file].original_filename 
        asset.save
      end
      Activity.add(_sid, "Updated file '#{@asset.file_file_name}'", current_user.id, "Files")
      redirect_to "/asset/#{@asset.id}"
    else
      render "show"
    end
  end

  def tags
    @asset = Asset.find_sys_id(_sid, params[:id])
    @asset.tags = params[:asset][:tags]
    Activity.add(_sid, "Updated file '#{@asset.file_file_name}' tags to '#{@asset.tags}'", current_user.id, "Files")
    @asset.save
    render :json=>""
  end

  def delete
    @asset = Asset.find_sys_id(_sid, params[:id])
    Activity.add(_sid, "Deleted file '#{@asset.file_file_name}'", current_user.id, "Files")
    @asset.destroy
    redirect_to "/assets"
  end

  def get
    get_asset(params[:id], params[:code])
  end

  def show
    @asset = Asset.where(:id=>params[:id]).first
  end

  def create
    ok = true

    assets = []

    params[:asset].each do |asset|
      @asset = Asset.new(:file => asset, :system_id=>_sid)
      assets << @asset
      ok = false unless @asset.save
    end

    if ok
      response = ''
      assets.each do |asset|
        Activity.add(_sid, "Added file '#{@asset.file_file_name}'", current_user.id, "Files")
        response += render_to_string(:partial=>"asset_entry", :locals=>{:asset=>asset, :mode=>"editor"})
      end
      render :json=>{:result => response}, :content_type=>"text/html"
      else
        render :json=>{:result=>"error"}, :content_type=>"text/html"
      end
  end

  def index
    @asset = Asset.new

    if params[:search]
      @assets = Asset.wild_search(params[:search], _sid)
    else
      @assets = Asset
    end
    
    @assets = @assets.sys(_sid).order("updated_at desc").page(params[:page]).per(params[:per] || (Preference.get_cached(_sid, "image_browser_per_page") || "10").to_i)

    if request.xhr?
      render "index", :formats=>[:js]
    else
      render "index", :formats=>[:html]
    end
  end
end
