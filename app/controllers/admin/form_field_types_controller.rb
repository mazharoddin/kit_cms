class Admin::FormFieldTypesController < AdminController

  def editoptions
    @form_field_type = FormFieldType.find_sys_id(_sid, params[:id])
    redirect_to "/admin/form_field_types" and return unless @form_field_type

    @referer = params[:referer] || request.referer 
    if request.put?
      options = params[:form_field_type][:options]

      if params[:text_options].not_blank?
        options += "|" if options.not_blank?
        options += params[:text_options].split("\n").collect { |s| s.is_blank? ? nil : s.strip }.compact.join('|')
      end
      if @form_field_type.update_attributes(:options=>options)
        redirect_to params[:referer], :notice=>"Options saved"
        return
      end
    end
  end

  def index
    @form_field_types = FormFieldType.sys(_sid).all
  end

  def show
    @form_field_type = FormFieldType.find_sys_id(_sid, params[:id])
  end

  def new
    @form_field_type = FormFieldType.new
    @form_field_type.allow_blank = 1
  end

  def create
    add_sid(:form_field_type)
    @form_field_type = FormFieldType.new(params[:form_field_type])
    @form_field_type.has_asset = ["file", "image"].include?(@form_field_type.field_type) ? 1 : 0
    if @form_field_type.save
      Activity.add(_sid, "Form field type '#{@form_field_type.name}' added", current_user, "Form")
      redirect_to "/admin/form_field_types/#{@form_field_type.id}", :notice => "Created new field type"
    else
      render :action => 'new'
    end
  end

  def edit
    @form_field_type = FormFieldType.find_sys_id(_sid, params[:id])
  end

  def update
    @form_field_type = FormFieldType.find_sys_id(_sid, params[:id])
    @form_field_type.has_asset = 1 if ["file", "image"].include?(@form_field_type.field_type)
    if @form_field_type.update_attributes(params[:form_field_type])
      Activity.add(_sid, "Form field type '#{@form_field_type.name}' updated", current_user, "Form")
      redirect_to "/admin/form_field_types/#{@form_field_type.id}", :notice=>"Updated field type"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @form_field_type = FormFieldType.find_sys_id(_sid, params[:id])
    if @form_field_type.form_fields.size>0
      redirect_to "/admin/form_field_types/#{@form_field_type.id}", :notice=>"Cannot delete because form fields are using this type" and return
    end

    Activity.add(_sid, "Form field type '#{@form_field_type.name}' deleted", current_user, "Form")
    @form_field_type.destroy
    redirect_to "/admin/form_field_types", :notice=>"Deleted field type"
  end

  private 

end
