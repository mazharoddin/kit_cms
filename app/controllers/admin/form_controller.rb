require 'csv'

class Admin::FormController < AdminController
  before_filter { licensed("forms") }

  def field
    @form = Form.find_sys_id(_sid, params[:id])
    @field = FormField.find_sys_id(_sid, params[:field_id])

    if request.post?
      if @field.form_field_type.field_type == 'location'
         params[:form_field][:geo_code_from_fields] = params[:fields_to_geocode].join('|')
      end
      if @field.update_attributes(params[:form_field])
        redirect_to "/admin/form/#{@form.id}/fields", :notice=>"Update field" and return
      end
    end
  end

  def generate_html
    @form = Form.find_sys_id(_sid, params[:id])

    render :partial=>"form/show", :locals=>{:form=>@form, :show_title=>true, :show_body=>true}
  end

  def fields
    @form = Form.sys(_sid).where(:id=>params[:id]).includes([{:form_field_groups=>:form_fields}, {:form_fields=>:form_field_type}]).first
  end

  def update_fields
    @form = Form.find_sys_id(_sid, params[:id])
    
    if params[:delete]
      field_id = params[:delete]
      field = @form.form_fields.where(["form_fields.id = ?", field_id])
      Activity.add(_sid, "Form '#{@form.title}' field '#{field.name}' deleted", current_user, "Form")
      @form.form_fields.delete(field)
      flash[:notice]="Field Deleted" 
    end

    if params[:add]
      form_field_type = FormFieldType.find_sys_id(_sid, params[:add])
      last_field = @form.form_fields.order("display_order").last
      if last_field
        next_display_order = last_field.display_order + 100
      else
        next_display_order = 1000
      end
      ff = FormField.new(:form_id=>@form.id, :display_order=>next_display_order, :form_field_type=>form_field_type, :is_mandatory=>false, :name=>form_field_type.name, :system_id=>_sid)
      
      if ff.save(:validate=>false)
        Activity.add(_sid, "Form '#{@form.title}' field '#{form_field_type.name}' added", current_user, "Form")
        flash[:notice]="Field Added"
      else
        flash[:notice]="Failed to add field"        
      end
    end 

    redirect_to "/admin/form/#{@form.id}/fields"
  end

  def list
    @form = Form.find_sys_id(_sid, params[:id])

    @subs = @form.form_submissions.sys(_sid).page(params[:page]).per(params[:per_page] || 50)
  end

  def browse
    @form = Form.find_sys_id(_sid, params[:id])
  
    @subs = @form.form_submissions.sys(_sid)
    if params[:sub_id]
      @subs = @subs.where(:id=>params[:sub_id]) 
    end  
    @subs = @subs.page(params[:page]).per(1)
  end

  def index
    @forms = Form.sys(_sid).page(params[:page]).per(50)
  end

  def show_submission 
    @sub = FormSubmission.sys(_sid).where(:id=>params[:id]).includes({:form_submission_fields=>{:form_field=>:form_field_type}}).first

    render :layout=>false
  end

  def update_submission
    @sub = FormSubmission.find_sys_id(_sid, params[:id])
    if params[:mark]
      Activity.add(_sid, "Form '#{@sub.form.title}' record #{@sub.id} marked", current_user)
      @sub.update_attributes(:marked=>params[:mark]) 
    end
    if params[:visible]
      Activity.add(_sid, "Form '#{@sub.form.title}' record #{@sub.id} visibility changed", current_user)
      @sub.update_attributes(:visible=>params[:visible]) 
    end

    render :json=>{:mark=>@sub.marked, :visible=>@sub.visible}
  end


  def destroy_submission
    @sub = FormSubmission.find_sys_id(_sid, params[:id])
    if @sub
      Activity.add(_sid, "Form '#{@sub.form.title}' record #{@sub.id} destroyed", current_user)
      @sub.destroy
      render :json=>{:delete=>"Deleted"}
    else
      render :json=>{:delete=>"Could not delete"}
    end
  end

  def export
    @form = Form.find_sys_id(_sid, params[:id])
    filename = @form.title.urlise + ".csv"    

    csv_headers(filename)


    csv_string = CSV.generate do |csv|
      csv << @form.form_fields.map { |ff| ff.name }
      @form.form_submissions.includes(:form_submission_fields).each do |fs|
        csv << fs.form_submission_fields.map { |fsf| fsf.value }
      end
    end
    render :text => csv_string 
  end

  def show
    @form = Form.find_sys_id(_sid, params[:id])
  end

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(params[:form])
    @form.system_id = _sid
    @form.locked_for_delete = true

    @form.submit_label = "Save" if @form.submit_label.is_blank?
    if @form.save
      Activity.add(_sid, "Form '#{@form.title}' created", current_user, "Form")

      redirect_to "/admin/form/#{@form.id}", :notice => "Successfully created Form"
    else
      render :action => 'new'
    end
  end

  def edit
    @form = Form.find_sys_id(_sid, params[:id])
  end

  def update
    @form = Form.find_sys_id(_sid, params[:id])
    if @form.update_attributes(params[:form])
      Activity.add(_sid, "Form '#{@form.title}' updated", current_user, "Form")
      redirect_to "/admin/form/#{@form.id}", :notice  => "Successfully updated form"
    else
      render :action => 'edit'
    end
  end

  def delete_submission
    @sub = FormSubmission.find_sys_id(_sid, params[:id])
    @sub.user.ban!(current_user.id) if @sub.user
    @sub.destroy
    Activity.add(_sid, "Form '#{@sub.form.title}' record #{@sub.id} deleted", current_user)

    redirect_to params[:after]
  end

  def show_hide_submission
    @sub = FormSubmission.find_sys_id(_sid, params[:id])
    @sub.visible = params[:mode]
    @sub.save
    Activity.add(_sid, "Form '#{@sub.form.title}' record #{@sub.id} visibility changed", current_user)

    redirect_to request.referer
  end

  def destroy
    @form = Form.find_sys_id(_sid, params[:id])
    if @form.locked_for_delete==1
      redirect_to "/admin/form/#{@form.id}", :notice=>"Cannot delete because form is locked" and return
    end
    Activity.add(_sid, "Form '#{@form.title}' deleted", current_user, "Form")
    @form.destroy

    redirect_to admin_forms_url, :notice => "Successfully destroyed form"
  end


end
