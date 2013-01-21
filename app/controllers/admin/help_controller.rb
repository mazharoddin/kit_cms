class Admin::HelpController < AdminController

  layout 'cms'
  def edit
    @help = Help.find(params[:id])
  end

  def images
    @images = HelpImage.order(:updated_at).page(params[:page]).per(20)

  end

  def delete_image
     HelpImage.delete(params[:id])

     redirect_to "/admin/help/images"
  end

  def upload
    image = HelpImage.new(params[:help_image])
    image.save
    redirect_to "/admin/help/images"
  end

  def update
    @help = Help.find(params[:id])

    if @help.update_attributes(params[:help])
      redirect_to "/db/help/#{@help.path}"
      return
    else
      render "edit"
    end
  end

  def index
    if params[:search]
      search_for = params[:search]

      search = Tire.search "kit_#{app_name.downcase}_helps" do
        query do
          string search_for, :fields=>["name", "body", "path"]
        end
      end
      @helps = search.results
    else      
      @helps = Help.order(:name).all
    end 
  end

  def destroy
    Help.delete(params[:id])
    redirect_to "/admin/helps"
  end

  def create
    help = Help.new
    help.name = params[:help][:name]
    help.path = help.name.urlise
    help.save

    redirect_to "/admin/help/#{help.id}/edit"
  end

end
