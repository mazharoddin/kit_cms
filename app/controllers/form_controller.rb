class FormController < KitController

  def xxxxshow
    @form = Form.sys(_sid).where(:id=>params[:id]).includes({:form_field_groups=>{:form_fields=>:form_field_type}}).first


    kit_render "form/show"
  end

  def search
    system_id = _sid
    if params[:for] 
      form_id = params[:form_id]
      search_for = params[:for]
      search_size = (params[:per] || "25").to_i
      the_page = (params[:page] || "1").to_i 

      search = Tire.search "kit_#{app_name.downcase}_form_submissions" do 
        query do
          boolean do 
            must do 
              string search_for
            end
          end
        end
        filter :term, :system_id=>system_id
        unless @mod
          filter :term, :visible=>1 
        end
        if form_id && form_id!='all'
          filter :term, :form_id=>form_id
        end
        from (the_page-1)*search_size 
        size search_size
      end

      @results = search.results
    else
      @results = nil
    end

    kit_render "search", :layout=>"application"
  end


  def save
    return unless anti_spam_okay?
    return unless sanity_check_okay?
    @form = Form.find_sys_id(_sid, params[:id])

    if @form.use_text_captcha?(request, current_user) 
      unless captcha_okay?
        flash[:notice] = "You didn't answer the 'Are you human?' question correctly"
        redirect_to request.referer + "?" + (@form.form_fields.collect { |field| "#{field.code_name}=#{params[field.code_name.to_sym]}" }.join('&'))
        return
      end
    end

    if params[:submission_id]
      sub = FormSubmission.find_sys_id(_sid, params[:submission_id])
      redirect_to "/" unless sub
      redirect_to "/" unless sub.can_edit?(current_user)      
      sub.form_submission_fields.destroy_all
    else
      sub = FormSubmission.new(:form_id=>params[:id], :ip=>request.remote_ip, :system_id=>_sid)
      sub.user_id = current_user.id if current_user
      sub.kit_session_id = session_id
      sub.save
    end

    @form.form_fields.each do |field|
      if value = (params["field_#{field.id}"] || params[field.code_name.to_sym])

        if field.form_field_type.field_type=='multicheckbox' && value.is_a?(Hash)
          value = value.values.join('|')
        elsif field.form_field_type.field_type=='multiselect' && value.is_a?(Array)
          value = value.join('|')      
        end
        fsf = FormSubmissionField.new(:form_field_id=>field.id, :value=>value, :system_id=>_sid)
        sub.form_submission_fields << fsf
      end
    end

    sub.geo_code

    if @form.notify.not_blank?
      @form.notify.split(',').each do |recipient|
        Notification.form_submission(sub_id, _sid, recipient).deliver
      end
    end

    if @form.log_activity?
      Activity.add(_sid, "Form '#{@form.title}' record #{sub.id} #{params[:submission_id] ? 'edited' : 'submitted'}", current_user ? current_user.id : nil, @form.title )
    end

    redirect_to @form.redirect_to
  end

  def delete
    sub = FormSubmission.find_sys_id(_sid, params[:id])
    redirect_to "/" and return if sub==nil || current_user==nil || sub.user_id != current_user.id
    title = sub.form.title

    sub.destroy
    redirect_to "/", :notice=>"#{title} Deleted"
  end
end
