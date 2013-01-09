module ForumHelper

  def forum_search(search_for, page, per, topic_ids = nil)
    # need to get list of topic_ids visible to this user (unless a topic_id is provided)
    # then do search, similar to forum_controller search
  end

  def display_name_for_moderator(user)
    color = 'black'
    color = 'orange' if user.forum_status > 2
    color = 'red' if user.forum_status > 5
    color = 'green' if user.forum_status == -1
    
    ( "[" +
      link_to(user.email, "/admin/users/#{user.id}") +
    "] <span class='#{color}'>" +
      user.display_name + 
      "</span> " +
      ('*' * user.spam_points.to_i)).html_safe
  end

  def extra_profile(post)
    b = Block.cache_get(_sid, "Forum: extra profile")

    return nil unless b

    render :inline=>b.body, :locals=>{:post=>post}
  end

  def search(options = {})
    render :partial=>"forum/search_form"
  end

  def forums_name
    Preference.getCached(_sid, "forums_name", "Forums")
  end

  def level_okay(minimum_level)
    return true if minimum_level == 0
    return false unless current_user
    return true if current_user.forum_level >= minimum_level
    return false
  end

  def order_arrow(o) 
    return (o == 'desc' ? "&darr;" : "&uarr;").html_safe
  end
end
