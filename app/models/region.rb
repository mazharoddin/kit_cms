class Region < ActiveRecord::Base
  has_many :calendar_entries
  has_many :subregions
end
