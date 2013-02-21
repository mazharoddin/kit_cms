class Admin::AdZonesController < AdminController

  before_filter :check_feature

  def create_block
    @ad_zone = AdZone.find_sys_id(_sid, params[:id])
    
    block = Block.sys(_sid).where(:name=>@ad_zone.block_name).first

    if block
      notice = 'Block already exists'
    else
      block = Block.create(:system_id=>_sid, :name=>@ad_zone.block_name, :description=>"System generated block to display an ad from zone '#{@ad_zone.name}'", :show_editors=>true, :all_templates=>true, :user_id=>current_user.id, :body=>"<% if params[:edit] %>[[ad will appear here]]<% else %><% ad = kit_ad_by_zone(#{@ad_zone.id}) %><%= kit_ad(ad.id) if ad %><% end %>")
      notice = 'Block created'
    end

    redirect_to [:admin, @ad_zone], :notice=>notice
  end

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
