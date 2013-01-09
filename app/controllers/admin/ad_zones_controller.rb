class Admin::AdZonesController < AdminController

  before_filter :check_feature

  def index
    @ad_zones = AdZone.sys(_sid).includes(:ad_unit)
    @ad_zones = @ad_zones.where(:ad_unit_id=>params[:ad_unit]) if params[:ad_unit] 
    @ad_zones = @ad_zones.page(params[:page]).per(50)
  end

  def show
    @ad_zone = AdZone.find_sys_id(_sid, params[:id])
  end

  def new
    @ad_zone = AdZone.new
    @ad_zone.period = "Months"
    @ad_zone.concurrency_limit = 1
    @ad_zone.priority = 10
    @ad_zone.minimum_period_quantity = 1
  end

  def create
    @ad_zone = AdZone.new(params[:ad_zone])
    @ad_zone.system_id = _sid
    if @ad_zone.save
      redirect_to [:admin, @ad_zone], :notice => "Successfully created Ad Zone"
    else
      render :action => 'new'
    end
  end

  def edit
    @ad_zone = AdZone.find_sys_id(_sid, params[:id])
  end

  def update
    @ad_zone = AdZone.find_sys_id(_sid, params[:id])
    if @ad_zone.update_attributes(params[:ad_zone])
      redirect_to [:admin, @ad_zone], :notice  => "Successfully updated Ad Zone"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @ad_zone = AdZone.find_sys_id(_sid, params[:id])
    @ad_zone.destroy
    redirect_to admin_ad_zones_url, :notice => "Successfully deleted Ad Zone"
  end

  def check_feature
    feature?("ads")
  end

end
