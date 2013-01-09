class Admin::TopicController < AdminController
  before_filter { licensed("forums") }

  before_filter :load_topic

  def show
  end

  def edit
  end

  def make
    v = params[:value]=='true' ? 1 : 0
    if params[:attr]=="visible"
      @topic.update_attributes(:is_visible=>v)
    end
    if params[:attr]=="open"
      @topic.update_attributes(:is_open=>v)
    end

    redirect_to "/admin/forums/topic/#{@topic.id}"
  end

  def update
    if @topic.update_attributes(params[:topic])
      redirect_to "/admin/forums/topic/#{@topic.id}"
    else
      render "edit"
    end
  end

  def destroy
    Topic.destroy(params[:id])
    flash[:notice] = "Topic Deleted"
    redirect_to "/admin/forums"
  end

  private 
  def load_topic
    @topic = Topic.find_sys_id(_sid, params[:id])
  end
end
