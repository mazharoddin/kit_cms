class Admin::KitEngagementController < AdminController

  def index
    @engagements = KitEngagement.sys(_sid).includes({:kit_session=>:user}).order("created_at desc").page(params[:page]).per(100)

  end
end
