class Admin::UserController < AdminController
  layout "cms-boxed" 


  def email
    @user = User.find_sys_id(_sid, params[:id])

    if request.post?
      note = UserNote.new(params[:user_note])
      note.user = @user
      note.category = "EMail #{current_user.email}"
      note.save
      Notification.send_message(note, _sid).deliver
      redirect_to "/admin/user/#{@user.id}", :notice=>"Message sent" 
    else
      @note = UserNote.new
    end
    

  end

  def generate_profile_html
    mode = params[:mode]
    @pro_forma = true
    if mode=='view' 
      @user = User.last
      mode = 'user'
    elsif mode=='owner'
      @user = current_user
      mode = 'user'
    end

    html = render_to_string "user/#{mode}_profile", :layout=>false
    if mode=='edit'
      html = html.gsub(/<input name=\"authenticity_token\" type=\"hidden\" value=\"[^\"]*" \/>/, '<input name="authenticity_token" type="hidden" value="" />')
    end
    render :text=>html, :layout=>false
  end


  
  def password
    @user = User.find_sys_id(_sid, params[:id])
    password = params[:user][:password]

    if password.not_blank?
      @user.user_notes << UserNote.new(:category=>"Password", :description=>"Reset by administrator", :created_by_id=>current_user.id)
      @user.password = params[:user][:password]

      @user.save
    end
    respond_with_bip(@user)
  end

  def attributes
    @attribute = UserAttribute.new
    @attributes = UserAttribute.sys(_sid).order(:order_by).all
    
    if request.post?
      Preference.set(_sid, "user_profile_edit_form", params[:edit_html], nil)
      Preference.set(_sid, "user_profile_view_form", params[:view_html], nil)
      Preference.set(_sid, "user_profile_owner_form", params[:owner_html], nil)
    end
    @edit_html = Preference.get_cached(_sid, "user_profile_edit_form") || ''
    @view_html = Preference.get_cached(_sid, "user_profile_view_form") || '' # it's not really a form, but for consistency with edit it's called a form here
    @owner_html = Preference.get_cached(_sid, "user_profile_owner_form") || '' # it's not really a form, but for consistency with edit it's called a form here
  end

  def attribute
    @attribute = UserAttribute.find_sys_id(_sid, params[:id])
  end

  def destroy_attribute
    @attribute = UserAttribute.find_sys_id(_sid, params[:id])
    UserAttribute.delete_all("id = #{params[:id]} and system_id = #{_sid}")
    UserAttributeValue.delete_all("user_attribute_id = #{params[:id]}")
    Activity.add(_sid, "Attribute '#{@attribute.name}' deleted", current_user, "Users")
    flash[:notice] = "Attribute deleted"
    redirect_to "/admin/users/attributes"
  end

  def update
    @user = User.find_sys_id(_sid, params[:id])
    if params[:user][:display_name].is_blank?
      params[:user][:display_name] = nil
    end
    @user.update_attributes(params[:user])
    respond_with_bip(@user)
  end

  def update_attribute
    @attribute = UserAttribute.find_sys_id(_sid, params[:id])
    @attribute.update_attributes(params[:user_attribute])
    if @attribute.save
      Activity.add(_sid, "Attribute '#{@attribute.name}' edited", current_user, "Users")
      flash[:notice] = "Attribute updated"
      redirect_to "/admin/users/attribute/#{@attribute.id}"
    else
      render "attribute"
    end
  end

  def add_user_to_group
    @user = User.find_sys_id(_sid, params[:id])
    @group = Group.find_sys_id(_sid, params[:group_id])
    @user.groups << @group

    @user.update_index
    flash[:notice] = "User added to group"
    Activity.add(_sid, "User '#{@user.email}' added to group '#{@group.name}'", current_user, "Users")
    redirect_to "/admin/user/#{@user.id}"
  end

  def remove_user_from_group
    @user = User.find_sys_id(_sid, params[:id])
    @group = Group.find_sys_id(_sid, params[:group_id])
    @user.groups.destroy(@group)
    @user.update_index
    flash[:notice] = "User removed from group"
    Activity.add(_sid, "User '#{@user.email}' removed from group '#{@group.name}'", current_user, "Users")
    redirect_to "/admin/user/#{@user.id}"
  end

  def help_mode
    Preference.set(_sid, 'show_help', params[:mode], current_user.id)
    render :js=>""
  end

  def attribute_value
    @user = User.find_sys_id(_sid, params[:id])

    uav = UserAttributeValue.find_or_initialize_by_user_id_and_user_attribute_id(@user.id, params[:attribute_id])
    uav.value = params[:user_attribute_value][:value]
    uav.save
    @user.update_index
    Activity.add(_sid, "Set attribute '#{uav.user_attribute.name}' to '#{uav.value}' for '#{@user.email}'", current_user, "Users")

    respond_with_bip(uav)
  end

  def create_attribute
    ua = UserAttribute.new(params[:user_attribute])
    ua.public_visible = false
    ua.user_visible = false
    ua.owner_visible = false
    ua.owner_editable = false
    ua.admin_visible = true
    ua.form_field_type_id = FormFieldType.sys(_sid).where(:field_type=>"line").first.id
    ua.code_name = ua.name.urlise
    if ua.code_name == "id" || ua.code_name == "submit"
      ua.code_name = "attribute_#{ua.code_name}"
    end
    ua.system_id = _sid
    if ua.save
      flash[:notice] = "New attribute created"
      Activity.add(_sid, "Created new user attribute '#{ua.name}'", current_user, "Users")
    else
      flash[:notice] = "Couldn't create attribute - does it already exist?"
    end
    redirect_to request.referer
  end  

  def index
    per_page = params[:per_page] || 50 
    system_id = _sid
    if params[:user_id].not_blank?
      @users = User.sys(_sid).where(:id=>params[:user_id]).page(1).per(per_page)
    else
      group = params[:grp_id]
      search_for = params[:for]
      parameter = params[:parameter]
      value = params[:value]

      export = params[:submit_button]=="export"

      param_hash = { parameter => value } if parameter

      if export
        from = 0
        size = 10000000
      else
        page = (params[:page] || 1).to_i
        from = ((page-1) * per_page) 
        size = per_page
      end

      musts = []

      musts << { :term => {:group_ids => group} } if group.not_blank?
      musts << { :query_string => {:fields => [ :email, :display_name ], :query => "*#{search_for.downcase}*" }} if search_for.not_blank?
      musts << { :term => {"attributes.#{parameter}"  => value.downcase} } if parameter.not_blank? && value.not_blank?

      if musts.size > 0  
        search = Tire.search "gnric_#{app_name.downcase}_users", {:query => { :bool => { :must => musts } }, :size=>per_page, :from=>from}
        search.size(per_page)
        search.from(from)
        search.filter :terms, :system_id=>system_id
        @users = search.results
      else 
        @users = User.sys(_sid).order(:email).page(params[:page]).per(per_page)
      end
    end

    if export
      stream_csv(@users)
      return
    end
    params[:page] = page
  end

  def add_note
    @user = User.find_sys_id(_sid, params[:id])
    @user_note = UserNote.new(params[:user_note])
    @user_note.created_by_id = current_user.id
    @user.user_notes << @user_note
    Activity.add(_sid, "Added note to user '#{@user.email}'", current_user, "Users")
    redirect_to "/admin/user/#{@user.id}"
  end

  def view
    @attribute = UserAttribute.new
    @user = User.sys(_sid).where(:id=>params[:id]).first
    @user_note = UserNote.new
  
    if params[:spam_points]  
      @user.update_attributes(:spam_points=>params[:spam_points])
      Activity.add(_sid, "Set spam points to #{params[:spam_points]} for user '#{@user.email}'", current_user, "Users")
      redirect_to "/admin/user/#{@user.id}" and return # don't want the user refreshing the set spam to zero URL
    end
    if params[:unlock]
      @user.unlock_access!
      Activity.add(_sid, "Unlocked user '#{@user.email}'", current_user, "Users")
    end
    if params[:ban]
      @user.ban!(current_user.id)
    end
    if params[:unban]
      @user.unban!(current_user.id)
    end
    if params[:designer]
      @user.designer_status(params[:designer]=="1")
    end
    if params[:moderator]
      @user.moderator_status(params[:moderator]=="1")
    end
    if params[:admin]
      @user.admin_status(params[:admin]=="1")
    end
    if params[:newsletter]
      @user.subscribe_newsletter = params[:newsletter]
      @user.save
    end
    if params[:forum_status]
      change = params[:forum_status]=="up" ? 1 : -1
      @user.forum_status += change
      @user.forum_status = 0 if @user.forum_level < 0 
      @user.save
      Activity.add(_sid, "Changed user '#{@user.email}' forum level by #{change} to #{@user.forum_status}", current_user, "Users")
    end
    if params[:forum_level]
      change = params[:forum_level]=="up" ? 1 : -1
      @user.forum_level += change
      @user.forum_level = 0 if @user.forum_level < 0 
      @user.save
      Activity.add(_sid, "Changed user '#{@user.email}' forum level by #{change} to #{@user.forum_level}", current_user, "Users")
    end

  end

  def become
    return unless current_user.admin?
    target = User.find_sys_id(_sid, params[:id])
    if target.ranking > current_user.ranking
      redirect_to "/db", :notice=>"You cannot become that user"
      return
    else
      sign_in(:user,  target)
      redirect_to "/", :notice=>"You've successfully become that user"
      return
    end
  end

  private
  def stream_csv(users)
    filename = params[:action] + ".csv"    

    #this is required if you want this to work with IE		
    csv_headers(filename)

    csv_string = CSV.generate do |csv|
      csv << ["id","email","groups"]
      users.each do |u|
        csv << [u.id, u.email, u.groups.join(", ")]
      end
    end
    render :text => csv_string 
  end

  
end
