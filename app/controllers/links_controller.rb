class LinksController < KitController

  def index
    params[:target_field] = 'link_external_url' if params[:target_field]=="undefined"

    if request.xhr? && can_use
      render "index", :formats=>[:js]
    else
      if current_user && can_use
        render :layout=>"minimal"
      else
        render "index_trial", :layout=>"minimal"
      end
    end
  end

  def files
    @assets = Asset.sys(_sid).per(params[:per] || 10).page(params[:page])

    render :layout=>"minimal"
  end
end
