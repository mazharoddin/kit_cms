class Admin::AdvertismentsController < AdminController
   
  before_filter :check_feature
  def index
    @ads = Ad.sys(_sid).includes({:ad_zones=>:ad_unit}).order("ads.updated_at desc")
    @ads = @ads.where("activated is not null").where("approved_by_id is null")
    @ads = @ads.page(params[:page]).per(25)
  end


  private

  def check_feature
    feature?("ads")
  end
end
