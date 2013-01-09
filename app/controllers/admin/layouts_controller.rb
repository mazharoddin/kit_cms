class Admin::LayoutsController < AdminController

  def index
    @layouts = Layout.sys(_sid).order(:name).page(params[:page]).per(50)

    @layout = Layout.new
  end

  def create
    @layout = Layout.new(params[:layout])
    @layout.locale = 'en'
    @layout.handler = 'haml'
    @layout.format = 'html'
    @layout.path = '.'
    @layout.partial = 0
    @layout.system_id = _sid
    @layout.body = <<DOC
!!!
/ Layout: #{@layout.name}
%html
  %head
    = render :partial=>"layouts/gnric_header"
    %style(type="text/css")
      div#edit_link { top:30px; }
  %body
    = yield
DOC
    @layout.user_id = current_user.id
    @layout.save
    Activity.add(_sid, "Created layout '#{@layout.name}'", current_user.id, "Layout")
    redirect_to "/admin/layouts"
  end

  def show 
    @layout = Layout.find_sys_id(_sid, params[:id])
  end

  def update 
    @layout = Layout.find_sys_id(_sid, params[:id])
    if @layout.update_attributes(params[:layout])
      Activity.add(_sid, "Updated layout '#{@layout.name}'", current_user.id, "Layout")
      redirect_to "/admin/layouts"
    else
      render "show"
    end
  end

  def destroy
    @layout = Layout.find_sys_id(_sid, params[:id])
    Activity.add(_sid, "Deleted layout '#{@layout.name}'", current_user.id, "Layout")
    Layout.destroy(params[:id])
    redirect_to "/admin/layouts"
  end

end
