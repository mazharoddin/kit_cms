class Admin::MailchimpController < AdminController

  def import
    gb = mailchimp_connect

    User.where("email <> '#{Preference.get_cached(_sid,'master_user_email')}'").find_each do |user|
      gb.list_subscribe({:id=>Preference.get_cached(user.system_id, "mailchimp_all_user_list"), :email_address=>user.email, :double_optin=>false, :merge_vars=>{:GROUPINGS=>[{:name=>"KIT Groups", :groups=>user.groups.collect {|g| g.name}.join(',')}]} }) rescue nil
    end

    redirect_to "/admin/mailchimp"
  end


  def index
    throw "No access" unless current_user.admin?

      mailchimp_connect
      @lists = @gibbon.lists["data"]
      
      if params[:make_default]
        # when making a list the default we must make sure that (a) it has a callback hook and (b) it has a group called KIT Groups.  that list must be the only one with those two things.
        Preference.set(_sid, "mailchimp_all_user_list", params[:make_default])
        Activity.add(_sid, "All User List set to #{params[:make_default]}", 0, "Mailchimp")
        @lists.each do |list|
          hooks = @gibbon.list_webhooks({:id=>list["id"]})
          found = false
          hooks.each do |hook|
            if hook["url"] =~ /mailchimp/
              found = true
              break
            end
          end

          if !found && list["id"] == params[:make_default]
#            @gibbon.list_webhook_add({:id=>list["id"], :url=>"http://requestb.in/qwlqxqqw", :campaign=>false})
            @gibbon.list_webhook_add({:id=>list["id"], :url=>"#{Preference.get_cached(_sid, "host")}/api/mailchimp?key=#{Preference.get_cached(_sid, 'mailchimp_callback_key')}", :campaign=>false})
          elsif found && list["id"] != params[:make_default]
            @gibbon.list_webhook_del({:id=>list["id"], :url=>"#{Preference.get_cached(_sid, "host")}/api/mailchimp?key=#{Preference.get_cached(_sid, 'mailchimp_callback_key')}"})
            #@gibbon.list_webhook_del({:id=>list["id"], :url=>"http://requestb.in/qwlqxqqw"})
          end 

          found_group = nil
          begin
            groups = @gibbon.list_interest_groupings({:id=>list["id"]}) 
          rescue 
            logger.debug "**** No interest groupings at the moment"
            groups = nil
          end
          if groups
            groups.each do |group|
              if group["name"] == "KIT Groups"
                found_group = group["id"]
                logger.debug found_group
                break  
              end
            end
            if found_group && list["id"] != params[:make_default]
              @gibbon.list_interest_grouping_del({:id=>list["id"], :grouping_id=>found_group})
            end
          end
          if found_group==nil && list["id"] == params[:make_default]
                logger.debug found_group
            @gibbon.list_interest_grouping_add({:id=>list["id"], :name=>"KIT Groups", :type=>"checkboxes", :groups=>Group.mailchimp_groups(_sid)}) 
          end
        end
        redirect_to "/admin/mailchimp" and return  
      end

      @default_list = Preference.get_cached(_sid, "mailchimp_all_user_list")
  end

  def callback
    key = Preference.get_cached(_sid, 'mailchimp_callback_key')
    if key.is_blank?
      render :text=>"no key set"
      return
    end

    if params[:key] != key
      Event.store("mailchimp callback", request, nil, nil, nil)
      head :bad_request
      return
    end

    type = params[:type]

    if type=='unsubscribe' || type=='subscribe'
      u = User.sys(_sid).where(:email=>params[:data][:email]).first

      head :ok and return unless u
      if type=='unsubscribe'
        u.update_attributes(:subscribe_newsletter=>0)
#      elsif type=='upemail'
#        u.update_attributes(:email=>params[:data][:new_email])
      elsif type=='subscribe'
        u.update_attributes(:subscribe_newsletter=>1)
      end
    end

    head :ok
  end


  private

end
