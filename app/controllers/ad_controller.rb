class AdController < KitController

  def buy
    options = JSON.parse(params[:options]) 

    @ad = Ad.new(params[:ad])
    @ad.duration = params[:ad][:duration].to_i
    zone = AdZone.find_sys_id(_sid, params[:zones].first)
    @ad.height = zone.height
    @ad.width = zone.width
    @ad.system_id = _sid
    @ad.user_id = current_user.id
    @ad.end_date = @ad.start_date + @ad.duration.send(zone.period.downcase) rescue nil
    @ad.activated = nil
    if @ad.save
      price = 0
      params[:zones].each do |z|
       next unless options["zones"].include?(z.to_i)
       zone = AdZone.find_sys_id(_sid, z) 
       @ad.ad_zones << zone
      end
      @ad.price_paid = @ad.cost
      @ad.tax_rate = @ad.current_tax_rate
      @ad.save
    else
      logger.debug @ad.errors.full_messages.join(' ')
      redirect_to options["failed"] and return 
    end    

    redirect_to "#{options['success']}?ad_id=#{@ad.id}"
  end

  def clicked
    ad = Ad.find_sys_id(_sid, params[:id])

    redirect_to "/", :notice=>"Ad not found" and return unless ad

    AdClick.create(:ad=>ad, :user=>current_user, :referrer=>request.referer, :ip=>request.remote_ip) unless params[:admin]

    redirect_to ad.link
  end

end
