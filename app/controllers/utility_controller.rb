require 'simple_rss'

class UtilityController < KitController

  BLOCK_SCORE_BAD_AUTH = 10
  before_filter :authenticate_user!, :only=>[:set_location]
 

  before_filter :can_moderate, :only=>[:user_email_to_ids]
  def user_email_to_ids
    render :json => User.sys(_sid).order(:email).where("email like '%#{params[:term]}%'").collect { |u| {:label=>u.email, :value=>u.id} }
  end

  def snippet_list
    @snippets = Snippet
                .includes(:user)
                .order("created_at desc")
                .where(:show_editors=>1)
                
    @snippets = @snippets.where("description like '%#demo%'") unless current_user && current_user.editor?
    @snippets = @snippets.all
    render "admin/snippet/list.html.haml", :layout=>false
  end

  def down_for_maintenance
    render :text=>Preference.get_cached(_sid, "down_for_maintenance_message"), :layout=>false, :status=>503
  end

  def markdown_preview
    render :text=>params[:body].sanitise.friendly_format.html_safe
  end

  def design_history
    @dh = DesignHistory.sys(_sid).where(:id=>params[:id]).first
    render "design_history", :layout=>"cms-boxed"
  end

  def addresses
    @addresses = Postcode.addresses(params[:postcode])
  end

  def external_link
    redirect_to "#{url}"
  end
  
  def postcode
    location_mod = Postcode.clean(params[:postcode])
    @pc = Postcode.find_by_input_postcode(location_mod)
    
    # redner postcode.rjs which basically just calls whatever callback function was specified as parameter, indicating success or failure
  end

  def set_location
    current_user.location = Location.find(params[:location_id])
    current_user.save

    @to_update = params[:to_update]
    @to_update ||= 'set_location'
  end

  def display_name_check
    if User.sys(_sid).where(:display_name=>params[:name]).count > 0 
      render :js=>"display_name_check('Name in use');"
    else
      render :js=>"display_name_check('');"
    end
  end  

  def fetch_rss
    content = open(params[:rss].gsub('&amp;', '&')).read
    html = params[:html]
    limit = (params[:limit] || "1000000").to_i
    truncate_body = (params[:truncate_body] || 100000).to_i

    rss = SimpleRss.parse content

    response = {}
    response[:title] = rss.channel.title
    response[:link] = rss.channel.link
    response[:items] = []
    c = 0
    rss.items.each do |rssitem|
      c += 1
      break if c > limit
      item = {}
      item[:title] = rssitem.title
      item[:link] = rssitem.link
      body = rssitem.description.gsub("&lt;","<").gsub("&gt;",">")
      body = strip_tags(body) if html=='strip'
      body = truncate(body, :length=>truncate_body, :ommission=>"...")
      item[:body] = body
      response[:items] << item
    end

    render :json=>response
  end

  def mercury_html
    render :layout=>false
  end

  def add_comment
    return :js=>"alert('Cannot submit a comment at this time');" unless anti_spam_okay?
    return :js=>"alert('Cannot submit a comment at this time');" unless sanity_check_okay?
    @comment = Comment.new(params[:comment])
    @comment.system_id = _sid
    @comment.user_id = current_user ? current_user.id : 0
    @comment.is_visible = 1
    if request.referer =~ /\/\/[^\/]+(\/.*)$/
      @comment.url = $1
    end
    @comment.save

    Activity.add(_sid, "Comment added to #{link_to @comment.url, @comment.url}", current_user ? current_user.id : 0, 'Comment')    

    if Preference.get_cached(_sid, 'moderate_comments')!='false'
      Notification.moderation_required("comment", "A comment has been added to #{Preference.get_cached(_sid, 'host')}#{@comment.url} which requires moderation. You can moderate comments here:  #{Preference.get_cached(_sid, 'host')}/admin/dashboard/user_comments", _sid).deliver
    end

    render :js=>"comment_added();"
  end

end
