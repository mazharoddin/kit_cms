class Calendar < ActiveRecord::Base
  belongs_to :user
  has_many :calendar_entries
  has_many :calendar_entry_types

  validates :name, :presence=>true, :uniqueness=>true, :length=>{:minimum=>1, :maximum=>200}

  def entries_between(start_date, end_date, filter, position = nil, distance = nil) 
    e = self.calendar_entries.where(["(start_date < ? and end_date > ?)", end_date, start_date]).includes({:location=>:subregion})

    if filter =~ /subregions.name/
      e = e.joins({:location=>:subregion})
    elsif filter =~ /location/
     e = e.joins(:location) 
    end

    if filter =~ /calendar_entry_types/ || filter =~ /calendar_entry_type_id/
      e = e.joins(:calendar_entry_type)
    end

    if position 
      e = e.near(position, distance || 25)
    end

    e = e.where(filter) if filter.not_blank? 
    e = e.all
  end
end
