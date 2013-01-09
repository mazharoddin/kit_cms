 require 'digest/md5'
 
 class Admin::StylesheetController < AdminController

  # TODO: What happens to stylesheet caching with multi server???
  #
  
  def index
    setup_index
  end

  def serve 
    name,fingerprint = params[:path].split('-')
     
    stylesheet = Stylesheet.fetch(_sid, name.downcase)
    response.headers['Content-Type'] = 'text/css'
    response.headers['Cache-Control'] = 'max-age=31536000, public'
    response.headers["Expires"] = CGI.rfc1123_date(Time.now + 360.days)
    render :text=>stylesheet.css, :layout=>false
  end

  def create
    add_sid(:stylesheet)
    @sheet = Stylesheet.new(params[:stylesheet])
    @sheet.user_id = current_user.id
    @sheet.body = Stylesheet.default_body
    if @sheet.save
      redirect_to "/admin/stylesheets"
    else
      setup_index
      render "index"
    end
  end

  def show
    @sheet = Stylesheet.find_sys_id(_sid, params[:id])
  end

  def update
    @sheet = Stylesheet.find_sys_id(_sid, params[:id])
    add_sid(:stylesheet)
    @sheet.body = params[:stylesheet][:body]
    begin
      @sheet.generate_css
    rescue Sass::SyntaxError => error
      @sheet = Stylesheet.new(params[:stylesheet])
      @sheet.id = params[:id]
      @sheet.system_id = _sid
      flash[:notice] = error.to_s
      render "show"
      return
    end

    if @sheet.update_attributes(params[:stylesheet])
      Rails.cache.delete(Stylesheet.cache_key(@sheet.name.downcase))
      @sheet.generate_css
      redirect_to "/admin/stylesheets"
    else
      render "show"
    end
  end

  def destroy
    Stylesheet.delete_all("id = #{params[:id]} and system_id = #{_sid}")

    redirect_to "/admin/stylesheets"
  end

  private 

  def setup_index
    @sheets = Stylesheet.sys(_sid).page(params[:page]).per(50)
    @sheet ||= Stylesheet.new 
  end    

end
