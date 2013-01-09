class Admin::GalleryController < AdminController
  before_filter { licensed("galleries") }

  def index
    @galleries = Gallery.sys(_sid).order("created_at desc").page(params[:page]).per(10)
    @gallery = Gallery.new
  end

  def create
    @gallery = Gallery.new(params[:gallery])
    @gallery.height = 400
    @gallery.width = 600
    @gallery.delay = 2000
    @gallery.transition_duration = 500
    @gallery.system_id = _sid
    if @gallery.save
      Activity.add(_sid, "Created gallery '#{@gallery.name}'", current_user.id, "Galleries")
      redirect_to "/admin/galleries", :notice=>"Gallery created" and return
    end
    @galleries = []
    render "index"
  end

  def show
    @gallery = Gallery.find_sys_id(_sid,params[:id])

    if params[:search]
      search = params[:search][:search]
      @images = Asset.sys(_sid).wild_search(search)
    else
      @images = Asset
    end
    
    @images = @images.order("updated_at desc")
    @images = @images.where(:is_image=>1) unless params[:files] 
    @images = @images.page(params[:page]).per(10)
  end

  def edit
    @gallery = Gallery.find_sys_id(_sid,params[:id])
  end

  def view
    @gallery = Gallery.find_sys_id(_sid,params[:id])

    render :partial=>"view", :locals=>{:gallery=>@gallery}
  end

  def update
    @gallery = Gallery.find_sys_id(_sid,params[:id])
    @gallery.update_attributes(params[:gallery])
    Activity.add(_sid, "Updated gallery '#{@gallery.name}'", current_user.id, "Galleries")

    redirect_to "/admin/gallery/#{@gallery.id}", :notice=>"Updated"
  end

  def sort_images
    @gallery = Gallery.find_sys_id(_sid,params[:id])
    o = 1

    params[:order].each do |asset_id|
      @gallery.gallery_assets.where(:asset_id=>asset_id).first.update_attributes(:display_order => o)
      o += 1
    end

    render :js=>"notice('Sorting saved');"
  end

  def delete
    @gallery = Gallery.find_sys_id(_sid,params[:id])
    Activity.add(_sid, "Deleted gallery '#{@gallery.name}'", current_user.id, "Galleries")
    @gallery.destroy
    redirect_to "/admin/galleries" 
  end

  def delete_image
    @gallery = Gallery.find_sys_id(_sid,params[:id])
    @asset = Asset.find_sys_id(_sid, params[:image_id])    
    if @asset && @gallery
      @gallery.assets.delete(@asset)
      render :js=>"remove_image_from_gallery(#{params[:image_id]}); notice('Image removed from gallery');"
    else
      render :js=>""
    end
  end

  def add_image
    @gallery = Gallery.find_sys_id(_sid,params[:id])
    @asset = Asset.find_sys_id(_sid, params[:image_id])

    if @asset && @gallery
      @gallery_asset = GalleryAsset.new(:gallery=>@gallery, :asset=>@asset, :display_order=>@gallery.assets.count + 1)
      @gallery_asset.save

      r = render_to_string(:partial=>"image_list_entry", :locals=>{:asset=>@gallery_asset}, :layout=>false)

      render :text=>r
    else
      render :text=>""
    end
  end

  def update_image
    @gallery_asset = GalleryAsset.find(params[:id])

    @gallery_asset.update_attributes(params[:gallery_asset])
    respond_with_bip(@gallery_asset)
  end

end
