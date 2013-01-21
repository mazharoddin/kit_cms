class Admin::SnippetController < AdminController

  layout "cms"

  def index
    @snippets = Snippet
                .includes(:user)
                .order("created_at desc")
    @snippets = @snippets.where('name like "%' + params[:for] + '%" or body like "%' + params[:for] + '%" or description like "%' + params[:for] + '%"') if params[:for].not_blank?
    @snippets = @snippets.page(params[:page]).per(10)
  end

  def fetch
    @snippet = Snippet.find_sys_id(_sid, params[:id])
    render :text=>@snippet.body, :layout=>false 
  end

  def new
    @snippet ||= Snippet.new
  end

  def show
    @snippet = Snippet.find_sys_id(_sid, params[:id])
  end

  def destroy
    @snippet = Snippet.find_sys_id(_sid, params[:id])
    Activity.add(_sid, "Deleted snippet '#{@snippet.name}'", current_user.id, "Snippets")
    @snippet.delete
    flash[:warn] = "Snippet deleted"
    redirect_to "/admin/snippet"
  end

  def update
    @snippet = Snippet.find_sys_id(_sid, params[:id])

    add_sid(:snippet)
    @snippet.update_attributes(params[:snippet])
    if @snippet.save
      Activity.add(_sid, "Updated snippet '#{@snippet.name}'", current_user.id, "Snippets")
      redirect_to "/admin/snippet/#{@snippet.id}"
      return
    else
      render "edit"
    end
  end

  def fetch
    @snippet = Snippet.find_sys_id(_sid, params[:id])
    render :text=>@snippet.body, :layout=>false
  end

  def edit
    @snippet = Snippet.find_sys_id(_sid, params[:id])
  end

  def create
    add_sid(:snippet)
    @snippet = Snippet.new(params[:snippet])
    @snippet.user_id = current_user.id
    if @snippet.save
      Activity.add(_sid, "Created snippet '#{@snippet.name}'", current_user.id, "Snippets")
      redirect_to "/admin/snippet/#{@snippet.id}"
      return
    else
      render "new"
    end
  end

end
