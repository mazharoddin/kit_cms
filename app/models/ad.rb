class Ad < ActiveRecord::Base
  include ActionView::Helpers
  attr_accessor :duration
  attr_accessor :not_found

  attr_accessible :impression_count
  has_many :order_items, :as=>:orderable
  belongs_to :sellable, :polymorphic=>true 

  belongs_to :user
  belongs_to :approved_by, :class_name=>"User"
  has_many :ad_zones_ads
  has_many :ad_zones, :through=>:ad_zones_ads
  has_many :ad_clicks

  validates :system_id, :presence=>true
  validates :user_id, :presence=>true
  validates :start_date, :presence=>true
  validates :end_date, :presence=>true
  validates :name, :presence=>true
 
  before_create :setup

  def cost # excluding tax
    c = 0
    self.ad_zones.each do |z|
      c += self.duration * z.price_per_period  
    end
    return c
  end

  def has_tax?
    Preference.get_cached(self.system_id, "charge_vat_on_ads")=="true"
  end

  def current_tax_rate
    return 0 unless has_tax?
    (Preference.get_cached(self.system_id, "vat_rate") || "0.20").to_f 
  end

  def tax
    self.price_paid * self.current_tax_rate
  end

  def cost_with_tax
    self.price_paid + self.tax
  end

  def setup
    self.weighting ||= 5
  end

  has_attached_file :creative, :styles=> lambda { |attachment| 
    sizes = {}
    sizes[:thumb] = "100x100>",
    sizes[:display] = "300x300"
    sizes
  }

  def ready?
    self.approved_by_id && self.is_active? && self.in_date?
  end

  def status
    return "Inactive" unless is_active?
    return "Unapproved" unless self.approved_by_id
    return "Out of date" unless in_date?
    return "Active"
  end

  def is_active?
    self.activated!=nil
  end

  def in_date?
    self.start_date < Time.now && self.end_date > Time.now
  end

  def zone_size
    "#{self.ad_zones.first.ad_unit.width}x#{self.ad_zones.first.ad_unit.height}"
  end

  def mark_paid(payment)
    self.payment_reference = payment.order.reference(payment.id)
    self.paid_at = Time.now
    self.activated = Time.now
    self.save
  end

  def mark_unpaid
    self.paid_at = nil
    self.activated = nil
    self.save
  end

  def render(options = {})
    ad = self

    if ad.creative_file_name
      content = "<img src='#{ad.creative.url(options[:preview] ? :thumb : :display)}' />".html_safe
    else
      content = ad.not_found ? "[[ad not found]]" : (ad.allow_html==1 ? ad.body : (h ad.body))
    end
    
    op = []
    op << "<div class='ad ad_#{ad.not_found ? 'missing' : ad.id}"
    ad.ad_zones.each do |zone|
     op << "ad_zone_#{zone.id} "
    end  unless ad.not_found

    op << "' style='display: inline-block;"
    op << "height: #{ad.height}px;" unless options[:preview] || ad.not_found
    op << "width: #{ad.width}px;" unless options[:preview] || ad.not_found
    op << "cursor: pointer;" if ad.link.not_blank? 
    op << "'"
    op << "onClick=\"document.location='\/ad\/clicked\/#{ad.id}#{'?admin=1' if options[:admin]}';\"" if ad.link.not_blank?
    op << ">"
    op << content
    op << "</div>"
    
    op.join('').html_safe
  end

  def self.ensure_ad(ad)
    return ad if ad
    ad = Ad.new
    ad.not_found = true
    return ad
  end

  def self.random_ad(ads)
    adsa = []
    ads.each do |ad|
      for i in 1..ad.weighting do
        adsa << ad
      end
    end 
    adsa[rand(adsa.length-1)]

  end    

  def impress
    self.update_attributes(:impression_count => self.impression_count + 1)

    return self
  end
end
