# TODO: DB

class AdZone < ActiveRecord::Base

  belongs_to :ad_unit

  has_many :ad_zones_ads
  has_many :ads, :through=>:ad_zones_ads

  def display_name_with_price
    "#{self.name} (#{self.width}x#{self.height}) @ &pound;#{('%.2f' % self.price_per_period)}/#{self.period.singularize}".html_safe
  end

  def display_name
    "#{self.name} (#{self.width}x#{self.height})"
  end

  def height
    self.ad_unit.height
  end

  def width
    self.ad_unit.width
  end

  def impression
    if self.impressions_from == nil || self.impressions_from < Time.now - 1.day
      self.impression_count = 1
      self.impressions_from = Time.now
    else
      self.impression_count += 1
    end
    self.save
  end

  def active_ads(options = {})
    options[:date] ||= Time.now

    a = self.ads.where(["? between ads.start_date and ads.end_date", options[:date]])
    a = a.where("ads.activated is not null") unless options[:include_inactive]
    a = a.where("ads.approved_by_id is not null") unless options[:include_unapproved]
  end

  def available?
    return true if self.concurrency == 0 
    return active_ads.count < self.concurrency
  end

  def AdZone.load_ads(sid, ids, options = {})
    ids = [ids] unless ids.instance_of?(Array)
    matching_ads = Ad.joins(:ad_zones).sys(sid).where("ad_zones.id in (#{ids.join(",")})").where(["? between ads.start_date and ads.end_date", Time.now])
    matching_ads = matching_ads.where("ads.activated is not null") unless options[:include_inactive]
    matching_ads = matching_ads.where("ads.approved_by_id is not null") unless options[:include_unaproved]
    return matching_ads
  end    
end
