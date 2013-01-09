class Subregion < ActiveRecord::Base
  belongs_to :region

  def self.find_by_postcode(postcode)
    if postcode.strip.upcase =~ /^([A-Z][A-Z]?)/

      prefix = '|' + $1 + '|'
      subregions = Subregion.arel_table
      Subregion.where(subregions[:postcode_prefix].matches("%#{prefix}%")).first
    else
      nil
    end
  end

end
