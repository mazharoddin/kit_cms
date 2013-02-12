class UserController < KitController

  layout Preference.get_cached!(0,"user_profile_layout", "application")
  append_view_path Layout.resolver  

  before_filter :authenticate

  def preferences
    @page_title = 'Preferences'
    @user = current_user


  end

  def profile
    @page_title = "Your Profile"
    @user = current_user
    show_profile(true)
  end

  def user_profile
    @user = User.find_sys_id(_sid,params[:id])
    @page_title = "Profile for '#{@user.display_name || 'Anonymous User'}'"
    show_profile(false)
  end


  def edit_profile
    form = Preference.get_cached(_sid, 'user_profile_edit_form')
    if form.not_blank?
      render :inline=>form, :layout=>Preference.get_cached!(0,"user_profile_layout", "application") #TODO sub in auth token
      return
    end
  end

  def attribute
    @user = current_user

    uav = UserAttributeValue.find_or_initialize_by_user_id_and_user_attribute_id(@user.id, params[:id])
    uav.value = params[:user_attribute_value][:value]
    uav.updated_by = current_user
    uav.system_id = _sid
    uav.save
    @user.update_index
    Activity.add(_sid, "Set attribute '#{uav.user_attribute.name}' to '#{uav.value}' by '#{@user.email}'", current_user, "Users")

    respond_with_bip(uav)
  end

  def remove_profile_attribute

    UserAttributeValue.delete_all(["user_id = #{current_user.id} and user_attribute_id = ?", params[:id]])
    redirect_to "/user/profile"
  end

  def update
    @user = current_user
    @errors = {}
    at_least_one = false
    all_okay = true

    UserAttribute.sys(_sid).where("owner_visible = 1").each do |ua|
      if val = params[ua.code_name.to_sym]
        if (ua.form_field_type.has_asset? && val) || (!ua.form_field_type.has_asset?)
          uav = UserAttributeValue.where(:user_id=>@user.id).where(:user_attribute_id=>ua.id).first
          unless uav
            uav = UserAttributeValue.create(:user_id=>@user.id, :user_attribute_id=>ua.id)
          end

          if ua.form_field_type.has_asset?
            uav.asset = val
            uav.value = ''
          else
            uav.value = val
          end
          uav.updated_by = current_user.id
          if uav.save
            at_least_one = true
          else
            all_okay = false
          end
          Activity.add(_sid, "Set attribute '#{uav.user_attribute.name}' to '#{uav.value}' by '#{@user.email}'", current_user, "Users")
        else
          if ua.is_mandatory?
            @errors[ua.id] = {:message=>"You must enter a value for '#{ua.name}'", :field=>"field_#{ua.id}"}
            all_okay = false
          end
        end
      end
    end

    if at_least_one
      @user.update_index
    end

    if all_okay 
      flash[:info] = "Profile updated"
      redirect_to "/user/profile"
    else
      flash[:info] = "There were errors"
      render "user/edit_profile"
    end
  end

  def display_name
    current_user.display_name = params[:user][:display_name]
    if current_user.display_name.is_blank?
      current_user.display_name = nil
    end
    current_user.save!
    redirect_to request.referer
  end

  def check_display_name
    name = params[:name]

    if (name.length<2)
      render :text=>"Too short"
    else
      if User.sys(_sid).where(:display_name=>name).count > 0
        render :text=>"Name in use"
      else
        render :text=> ""
      end
    end
  end

  def preferences
    @forum_user = current_user.forum_user

    if request.put?
      if @forum_user.update_attributes(params[:forum_user])
        redirect_to "/user/preferences", :notice=>"Preferences updated"
        return
      end
    end

    kit_render "preferences", :layout=>Preference.get_cached!(_sid,"user_profile_layout", "application")
  end

  private

  def show_profile(owner)
    render :text=>"User not found" and return unless @user

    form = Preference.get_cached(_sid, "user_profile_#{owner ? 'owner' : 'view'}_form")
    if form.not_blank?
      render :inline=>form, :layout=>Preference.get_cached!(0,"user_profile_layout", "application") 
    else
      render "user_profile"
    end
  end
  
end
