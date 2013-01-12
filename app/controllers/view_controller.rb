class ViewController < KitController
  prepend_view_path Layout.resolver

  def show
    view_name = params[:view_name]
    view = View.where(:name=>view_name).sys(_sid).first
    render :text=>get_view_content(view), :layout=>view.layout.path
  end
end
