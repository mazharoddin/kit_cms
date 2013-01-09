module CommentsHelper
  
  def comments(options = {})
    @comment = Comment.new

    if current_user
      @comment.user_email = current_user.email
      @comment.user_name = current_user.display_name
    end

    options[:show_form] = options[:force_form] || (@page && (@page.allow_anonymous_comments? || (@page.allow_user_comments? && current_user)))
    options[:show_comments] ||= true

    # already commented?
    if options[:show_form] && current_user && Preference.get_cached(_sid, "one_comment_per_user")=='true'
      url = strip_url(request.fullpath)
      options[:show_form] = false if Comment.sys(_sid).where(:url=>url).where(:user_id=>current_user.id).count > 0
    end

    render partial:"pages/user_comments", :locals=>{:options=>options}
  end

  def comments_display(options = {})
    options[:show_form] = false
    comments(options)
  end

  def load_comments(url, options = {})
    surl = strip_url(url)
    c = Comment.sys(_sid).where(:url=>surl)
    options[:order] ||= "created_at desc"
    c = c.order(options[:order])
    c = c.where(:is_visible=>1) unless options[:dont_visibility]
    if Preference.get_cached(_sid, "moderate_comments")!='false'
      c = c.where(:is_moderated=>1) unless options[:dont_moderation]
    end
    unless options[:no_pagination]
      c = c.page(params[:cpage]) 
      c = c.per(options[:per] || 3) 
    else
      c.all
    end
  end

  def strip_url(url)
    if url =~ /\?cpage\=\d+$/ # if cpage=X is the only parameter, remove it
      return url.sub(/\?cpage\=\d+/, '')
    elsif url =~ /cpage\=\d+/ # if cpage=X is a parameter, remove it
      return url.sub(/cpage\=\d+/, '')
    else 
      return url
    end
  end    
end
