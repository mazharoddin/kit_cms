class Admin::AdsController < AdminController
  before_filter :check_feature

  def activate
    @ad = Ad.find_sys_id(_sid, params[:id])
    if params[:mode]=='approve'
      @ad.update_attributes(:approved_by_id=>current_user.id)
      notice = "Ad is now approved"
    elsif params[:mode]=='activate'
      @ad.update_attributes(:activated=>Time.now)
      notice = "Ad is not activated"
    else
      @ad.update_attributes(:activated=>nil)
      notice = "Ad is now deactivated"
    end

    redirect_to request.referer, :notice=>notice
  end

  def index
    @ads = Ad.sys(_sid).includes({:ad_zones=>:ad_unit}).order("ads.updated_at desc")
    @ads = @ads.joins(:ad_zones).where("ad_zones.id = #{params[:zone_id]}") if params[:zone_id] 
    @ads = @ads.where(:user_id=>params[:user_id]) if params[:user_id]
    @ads = @ads.page(params[:page]).per(25)
  end

  def show
    @ad = Ad.find_sys_id(_sid, params[:id])
  end

  def new
    @ad = Ad.new
    @ad.weighting = 5
  end

  def create
    @ad = Ad.new(params[:ad])
    @ad.system_id = _sid
    @ad.activated = Time.now
    @ad.approved_by_id = current_user.id

    zones = check_zones
    if zones.instance_of?(String)
      render :action=>'new', :notice=>zones
      return
    end

    if @ad.save && params[:ad_zones].length>0
      zones.each { |zone| @ad.ad_zones << zone }
      @ad.height = @ad.ad_zones.first.ad_unit.height
      @ad.width = @ad.ad_zones.first.ad_unit.width
      redirect_to [:admin, @ad], :notice => "Successfully created ad."
    else
      render :action => 'new'
    end
  end

  def edit
    @ad = Ad.find_sys_id(_sid, params[:id])
  end

  def update
    @ad = Ad.find_sys_id(_sid, params[:id])

    zones = check_zones
    if zones.instance_of?(String)
      @ad.errors.add(:ad_zones, zones)
      render :action=>'edit'
      return
    end
    
    if @ad.update_attributes(params[:ad]) && params[:ad_zones].length>0
      @ad.ad_zones.delete_all
      zones.each { |zone| @ad.ad_zones << zone }
      redirect_to [:admin, @ad], :notice  => "Successfully updated ad."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @ad = Ad.find_sys_id(_sid,params[:id])
    @ad.destroy
    redirect_to admin_ads_url, :notice => "Successfully destroyed ad."
  end

  private
  def check_feature
    feature?("ads")
  end

  def check_zones
    zones = []
    height = 0
    width = 0
    params[:ad_zones].each do |z| 
      zone = AdZone.find(z) 
      if height==0
        height = zone.height
        width = zone.width
      end
      if zone.height != height || zone.width != width
        return "Not all the zones are the same size"
      end
      zones << zone
    end
   
    if zones.size==0 
      return "No zones selected"
    end
    
    return zones
  end    
end
