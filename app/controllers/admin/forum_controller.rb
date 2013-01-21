class Admin::ForumController < AdminController
  before_filter { licensed("forums") }

  layout 'cms'


  def index
   @topic_category ||= TopicCategory.new 
   @topic ||= Topic.new
   @selected_cat = params[:selected_cat]
  end

  def delete_category
    @category = TopicCategory.find_sys_id(_sid, params[:id])

    if @category.topics.count > 0 
      flash[:notice] = "This category can't be deleted because it contains topic(s).  Delete those first."
    else
      TopicCategory.delete_all("id = #{params[:id]} and system_id = #{_sid}")
      flash[:notice] = "Category deleted"
    end

    redirect_to "/admin/forums"
  end

  def edit_category
    @category = TopicCategory.find_sys_id(_sid, params[:id])
    render "admin/forum/category"
  end

  def update_category
    @category = TopicCategory.find_sys_id(_sid, params[:id])
    if @category.update_attributes(params[:topic_category])
      flash[:notice] = "Category Updated"
      redirect_to "/admin/forums"
    else
      render "admin/forum/category"
    end
  end


  def create_topic
    add_sid(:topic)
    @topic = Topic.new(params[:topic])
    @topic.is_open = true
    @topic.system_id = _sid
    @topic.is_visible = true
    @topic.read_access_level = 0
    @topic.write_access_level = 1

    @selected_cat = @topic.topic_category_id
   @topic_category ||= TopicCategory.new 

    if @topic.save
      flash[:notice] = "Topic created"
      redirect_to "/admin/forums?selected_cat=#{@selected_cat}"
    else
      render "index"
    end
  end

  def create_category
    add_sid(:topic_category)
    @topic_category = TopicCategory.new(params[:topic_category])

    @topic_category.read_access_level = 0
    @topic_category.write_access_level = 1
    @topic_category.is_open = true
    if @topic_category.save
      flash[:notice] = "Category created"
      redirect_to "/admin/forums"
    else
      @topic ||= Topic.new
      render "index"
    end 
  end
end
