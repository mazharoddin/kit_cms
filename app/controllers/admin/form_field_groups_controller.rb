class Admin::FormFieldGroupsController < AdminController

  def index
    @form = Form.sys(_sid).where(:id=>params[:form_id]).first
    redirect_to "/admin/forms", :notice=>"Can't find that field group" and return unless @form
    @form_field_groups = @form.form_field_groups
  end

  def show
    @form_field_group = FormFieldGroup.find_sys_id(_sid, params[:id])
    @form = @form_field_group.form
  end

  def new
    @form = Form.sys(_sid).where(:id=>params[:form_id]).first
    @form_field_group = FormFieldGroup.new
    @form_field_group.form = @form
    @form_field_group.order_by = @form.form_field_groups.last.order_by + 100 rescue 100
  end

  def create
    @form_field_group = FormFieldGroup.new(params[:form_field_group])
    @form_field_group.system_id = _sid
    if @form_field_group.save
      redirect_to [:admin, @form_field_group], :notice => "Successfully created field group"
    else
      render :action => 'new'
    end
  end

  def edit
    @form_field_group = FormFieldGroup.find_sys_id(_sid, params[:id])
    @form = @form_field_group.form
  end

  def update
    @form_field_group = FormFieldGroup.find_sys_id(_sid, params[:id])
    if @form_field_group.update_attributes(params[:form_field_group])
      redirect_to [:admin, @form_field_group], :notice  => "Successfully updated field group"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @form_field_group = FormFieldGroup.find_sys_id(_sid, params[:id])
    form_id = @form_field_group.form_id
    @form_field_group.destroy
    redirect_to "/admin/form_field_groups?form_id=#{form_id}", :notice => "Successfully delete field group"
  end
end

