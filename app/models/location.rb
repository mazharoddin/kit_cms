class Location < ActiveRecord::Base
  belongs_to :subregion

  validates :postcode, :presence=>true, :if=>"Preference.get_cached(self.system_id, 'postcode_mandatory_on_cal_entry')"

  validate :postcode_has_region, :if=>"Preference.get_cached(self.system_id, 'postcode_mandatory_on_cal_entry')"

  before_save :update_subregion

  geocoded_by :display
  after_validation :geocode


  def postcode_has_region
    sr = find_subregion(postcode)
    if sr==nil
      errors.add(:postcode, "not recognised")
    end
  end

  def is_web?
    self.postcode.strip.downcase=='web'
  end

  def display
    return "Web" if self.is_web?
    d = []
    d << self.address1 unless self.address1.is_blank?
    d << self.address2 unless self.address2.is_blank?
    d << self.address3 unless self.address3.is_blank?
    d << self.city unless self.city.is_blank?
    d << self.postcode unless self.postcode.is_blank?
    d << self.country unless self.country.is_blank?

    d.join(", ")
  end

  def update_subregion
    self.subregion = find_subregion(self.postcode)
  end

  def find_subregion(pc)
    pc.strip.downcase=='web' ? Subregion.where(:name=>'Web').first : Subregion.find_by_postcode(pc)
  end


end
