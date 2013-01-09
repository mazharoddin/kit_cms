module Admin::TopicHelper

  def topic_path(topic)
    "/admin/forums/topic/#{topic.id}"
  end
  
  def edit_topic_path(topic)
    "/admin/forums/topic/#{topic.id}/edit"
  end

  def access_list(current, options={})
    c = current.to_i if current
    c ||= 0
    s = ""
    
    s = "<option value='0' #{'selected' if c==0}>Anyone</option>" unless options[:include_anyone]==false
  
    s += "<option value='1' #{'selected' if c==1}>Any registered user</option>"

    s += [2,3,4,5,6,7,8,9].map { |l|
      "<option value='#{l}' #{'selected' if l==c}>Level #{l} User</option>"
    }.join("") 

    return s.html_safe
  end

end
