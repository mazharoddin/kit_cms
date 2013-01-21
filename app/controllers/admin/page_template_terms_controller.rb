class Admin::PageTemplateTermsController < AdminController

  layout "cms"

  def index
    @page_template_terms = PageTemplateTerm.where(:page_template_id=>params[:page_template_id]).sys(_sid).all
  end

  def show
    @page_template_term = PageTemplateTerm.find_sys_id(_sid, params[:id])
  end

  def new
    @page_template_term = PageTemplateTerm.new
    @page_template_term.page_template_id = params[:page_template_id]
    @page_template_term.id = 0
  end


  def create
    params[:page_template_term].delete(:id)
    @page_template_term = PageTemplateTerm.new(params[:page_template_term])
    @page_template_term.system_id = _sid
    @page_template_term.created_by = current_user

    if @page_template_term.save
      redirect_to "/admin/page_template_terms?page_template_id=#{@page_template_term.page_template_id}", :notice => "New term created"
    else
      render :action => 'new'
    end
  end

  def edit
    @page_template_term = PageTemplateTerm.find_sys_id(_sid, params[:id])
  end

  def update
    @page_template_term = PageTemplateTerm.find_sys_id(_sid, params[:id])
    if @page_template_term.update_attributes(params[:page_template_term])
      redirect_to "/admin/page_template_terms?page_template_id=#{@page_template_term.page_template_id}", :notice  => "Successfully updated term"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @page_template_term = PageTemplateTerm.find_sys_id(_sid, params[:id])
    @page_template_term.destroy
    redirect_to "/admin/page_template_terms?page_template_id=#{@page_template_term.page_template_id}", :notice => "Successfully deleted term"
  end
end
