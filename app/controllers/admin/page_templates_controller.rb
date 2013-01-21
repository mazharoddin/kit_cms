class Admin::PageTemplatesController < AdminController
  layout "cms"
 
  def pages
   @page_template = PageTemplate.sys(_sid).where(:id=>params[:id]).first
  
   @pages = @page_template.pages.includes(:status).page(params[:page]).per(100)
  end

  def index
    @page_templates = PageTemplate.sys(_sid).page(params[:page]).per(50)
  end

  def show
    @page_template = PageTemplate.sys(_sid).where(:id=>params[:id]).includes(:mobile_version).first
  end

  def new
    @page_template = PageTemplate.new
  end

  def create
    add_sid(:page_template)
    @page_template = PageTemplate.new(params[:page_template])
    
    if PageTemplate.count==0
      @page_template.is_default = 1
    end
    @page_template.user_id = current_user.id
    if @page_template.save
      Activity.add(_sid, "Created Page Template '#{@page_template.name}'", current_user.id, "Page Template")
      redirect_to [:admin, @page_template], :notice => "Successfully created page template."
    else
      render :action => 'new'
    end
  end

  def edit
    @page_template = PageTemplate.where(:id=>params[:id]).sys(_sid).first
  end

  def update
    @page_template = PageTemplate.where(:id=>params[:id]).sys(_sid).first
    @page_template.user_id = current_user.id
    if @page_template.update_attributes(params[:page_template])
      Activity.add(_sid, "Updated Page Template '#{@page_template.name}'", current_user.id, "Page Template")
      redirect_to [:admin, @page_template], :notice  => "Successfully updated page template."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @page_template = PageTemplate.where(:id=>params[:id]).sys(_sid).first
    Activity.add(_sid, "Deleted Page Template '#{@page_template.name}'", current_user.id, "Page Template")
    @page_template.destroy
    redirect_to admin_page_templates_url, :notice => "Successfully destroyed page template."
  end
end
