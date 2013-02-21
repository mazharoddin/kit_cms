module AdsHelper

  def kit_pay_for_ad(id, options = {}) 
    begin
      return "pay form will appear here" unless id 
      @ad = Ad.find_sys_id(_sid, id)
      return "invalid user" unless @ad.user_id == current_user.id
      
      return "These ads have already been paid for" if @ad.paid_at
      @order = Order.new
      @order.email = @ad.user.email

      kit_render :partial=>"order/pay_for_ads", :locals=>{:options=>options}
    rescue Exception => e
      e.message
    end
  end

  def kit_ad_buy_form(zones, options = {})
    begin
      @ad = Ad.new
      @zones = AdZone.sys(_sid).where("ad_zones.id in (#{zones.join(',')})").all
      options[:zones] = zones 
      kit_render partial:"ad/buy", :locals=>{:options=>options}
    rescue Exception => e
      e.message + e.backtrace.join("<br/")
    end
  end

  def kit_ad_by_unit(unit_id, options = {})
    return "[[ads may appear here]]" if params[:edit]
    begin
      possible_zones = []
      highest_priority = nil
      AdZone.sys(_sid).where(:ad_unit_id=>unit_id).where("ad_zones.url_pattern is not null").order("ad_zones.priority desc").all.each do |zone|
        pattern = zone.url_pattern.gsub("/",'\/').gsub("*",".*")
        logger.debug "#{request.fullpath} =~ #{pattern}"
        next unless request.fullpath =~ /#{pattern}/
          highest_priority = zone.priority unless highest_priority
        break if zone.priority < highest_priority
        possible_zones << zone.id
      end

      if possible_zones.length>0 
        return kit_ad_by_zone(possible_zones, options)
      else
        return nil
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      e.message
    end
  end

  def kit_ad_by_zone(ids, options = {})
    begin
      matching_ads = AdZone.load_ads(_sid, ids, options)
      return nil unless matching_ads && matching_ads.size>0
     
      Ad.random_ad(matching_ads)
    rescue Exception => e
      e.message 
    end
  end

  def kit_render_ad_by_zone(ids, options = {})
    kit_ad_by_zone(ids, options).impress.render
  end

  def kit_ad(id, options = {})
    begin
      ad = Ad.sys(_sid).where(:id=>id).includes(:ad_zones).first
      
      ad = Ad.ensure_ad(ad)
      ad.impress
      ad.render
    rescue Exception => e
      e.message
    end
  end

  def zone_with_price(zone)
    "#{zone.name} @ #{pounds(zone.price_per_period)}/#{zone.period}"
  end
end
