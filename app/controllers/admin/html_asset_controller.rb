 require 'digest/md5'
 
 class Admin::HtmlAssetController < AdminController

  def index
    setup_index
  end

  # replace with model which writes itself to File system and is served up by webserver
  def serve 
    name,stamp = params[:path].split('-')
    asset = HtmlAsset.fetch(_sid, name.downcase, params[:format])
    response.headers['Content-Type'] = "text/#{asset.file_type}"
    response.headers['Cache-Control'] = 'max-age=31536000, public'
    response.headers["Expires"] = CGI.rfc1123_date(Time.now + 360.days)
    mime_type = Mime::Type.lookup_by_extension(asset.file_type)
    content_type = mime_type.to_s unless mime_type.nil?
    
    render :inline=>asset.compiled, :type=>:erb, :layout=>false, :mime_type => content_type
  end

  def create
    add_sid(:html_asset)
    @asset = HtmlAsset.new(params[:html_asset])
    @asset.user_id = current_user.id
    @asset.body = HtmlAsset.default_body(@asset.file_type)
    if @asset.save
      Activity.add(_sid, "Create '#{@asset.name}' #{@asset.file_type.upcase}", current_user.id, "HTML Asset")
      redirect_to "/admin/html_assets"
    else
      setup_index
      render "index"
    end
  end

  def show
    @html_asset = HtmlAsset.find_sys_id(_sid, params[:id])
  end

  def update
    @html_asset = HtmlAsset.find_sys_id(_sid, params[:id])
    add_sid(:html_asset)
    @html_asset.body = params[:html_asset][:body]
    @html_asset.file_type = params[:html_asset][:file_type]
    begin
      @html_asset.generate_compiled
    rescue Sass::SyntaxError => error
      @html_asset = HtmlAsset.new(params[:html_asset])
      @html_asset.id = params[:id]
      @html_asset.system_id = _sid
      flash[:notice] = error.to_s
      render "show"
      return
    end

    if @html_asset.update_attributes(params[:html_asset])
      Activity.add(_sid, "Edit '#{@html_asset.name}' #{@html_asset.file_type.upcase}", current_user.id, "HTML Asset")
      HtmlAsset.clear_cache(@html_asset)
      if params[:submit_button]=="save-and-edit-again"
        redirect_to "/admin/html_asset/#{@html_asset.id}#editor"
      else
        redirect_to "/admin/html_assets"
      end
    else
      render "show"
    end
  end

  def destroy
    @html_asset = HtmlAsset.find_sys_id(_sid, params[:id])
    HtmlAsset.delete_all("id = #{params[:id]} and system_id = #{_sid}")
    Activity.add(_sid, "Delete '#{@html_asset.name}' #{@html_asset.file_type.upcase}", current_user.id, "HTML Asset")

    redirect_to "/admin/html_assets"
  end

  private 

  def setup_index
    @assets = HtmlAsset.sys(_sid).page(params[:page]).per(50)
    @asset ||= HtmlAsset.new 
  end    

end
