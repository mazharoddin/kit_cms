class ImagesController < GnricController

  respond_to :json, :html

  def media_modal
    
  end

  def create
    add_sid(:image)
    @image = Asset.new(params[:image])
    unless current_user
      page_id = get_page_id_from_referer
      @image.tags = "##{page_id}"
    end
    @image.save
    logger.debug "Sending image #{@image.url}"
    respond_with @image
  end

  def destroy
    can_use
    @image = Asset.find_sys_id(_sid, params[:id])
    @image.destroy
    respond_with @image
  end

  def update
    can_use
    @image = Asset.sys(_sid).where(:id=>params[:id]).first
    @image.update_attributes(params[:asset])
    respond_to do |format|
      format.json { respond_with_bip(@image) }
    end
  end

  def index
    if params[:search]
      search = params[:search][:search]
      @images = Asset.wild_search(search, _sid)
    else
      @images = Asset
    end
    params[:page_id] ||= -1 # precent any funny business
    @images = @images.where("tags like '%#demo%' or tags like '%#trial-#{params[:page_id]}%'") unless current_user
    @images = @images.order("updated_at desc").sys(_sid)
    @images = @images.where(:is_image=>1) unless params[:files] 
    @images = @images.page(params[:page]).per((Preference.get_cached(_sid, "image_browser_per_page") || "10").to_i)
    render :layout=>"minimal"
  end

  private

  def get_page_id_from_referer
    request.referer =~ /\/(trial\-\d+)\?/
    return $1
  end
end
