class Admin::PreferenceController < AdminController

  layout "cms-boxed"

  def index
    @user_link = UserLink.new

    if params[:del_link]
      UserLink.delete(params[:del_link])
    end

    [ [:status, "show_status_box"],
      [:activity, "show_activity_box"],
      [:todo, "show_todo_box"],
      [:recent, "show_recent_pages_box"],
      [:links, "show_links_box"],
      [:page_click, "page_click"],
      [:advanced, "advanced_mode" ],
      [:hide_locked, "hide_locked" ],
    ].each do |p, name|
      if params[p]
        Preference.set(_sid, name, params[p], current_user.id)
      end
    end

    if request.xhr?
      render :text=>""
      return
    end
  end

  def update
   if params[:user_link]
      @user_link = UserLink.create(params[:user_link])
      current_user.user_links << @user_link
    end

   redirect_to "/admin/preference"
  end
end
