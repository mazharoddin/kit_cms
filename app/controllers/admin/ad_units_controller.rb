class Admin::AdUnitsController < AdminController

  layout 'cms-boxed'

  def create_block
    @ad_unit = AdUnit.find_sys_id(_sid, params[:id])
    
    block = Block.sys(_sid).where(:name=>@ad_unit.block_name).first

    if block
      notice = 'Block already exists'
    else
      block = Block.create(:system_id=>_sid, :name=>@ad_unit.block_name, :description=>"System generated block to display an ad of size '#{@ad_unit.name}'", :show_editors=>true, :all_templates=>true, :user_id=>current_user.id, :body=>"<%= gnric_ad_by_unit(#{@ad_unit.id}) %>")
      notice = 'Block created'
    end

    redirect_to [:admin, @ad_unit], :notice=>notice
  end

  def index
    @ad_units = AdUnit.sys(_sid).all
  end

  def show
    @ad_unit = AdUnit.find_sys_id(_sid, params[:id])
  end

  def new
    @ad_unit = AdUnit.new
  end

  def create
    @ad_unit = AdUnit.new(params[:ad_unit])
    @ad_unit.system_id = _sid
    if @ad_unit.save
      Activity.add(_sid, "Ad Unit '#{@ad_unit.name}' created", current_user.id, "Ads", '')
      redirect_to [:admin, @ad_unit], :notice => "Successfully created Ad Unit"
    else
      render :action => 'new'
    end
  end

  def edit
    @ad_unit = AdUnit.find_sys_id(_sid, params[:id])
  end

  def update
    @ad_unit = AdUnit.find_sys_id(_sid, params[:id])
    if @ad_unit.update_attributes(params[:ad_unit])
      Activity.add(_sid, "Ad Unit '#{@ad_unit.name}' updated", current_user.id, "Ads", '')
      redirect_to [:admin, @ad_unit], :notice  => "Successfully updated Ad Unit"
    else
      render :action => 'edit'
    end
  end

  def destroy
    @ad_unit = AdUnit.find_sys_id(_sid, params[:id])
    if @ad_unit.ad_zones.count > 0
      redirect_to admin_ad_units_url, :notice=>"Cannot delete whilst Ad Zones are using this unit" and return
    end
    Activity.add(_sid, "Ad Unit '#{@ad_unit.name}' deleted", current_user.id, "Ads", '')
    @ad_unit.destroy
    redirect_to admin_ad_units_url, :notice => "Successfully deleted Ad Unit"
  end

  private

  def check_feature
    feature?("ads")
  end
  
end
