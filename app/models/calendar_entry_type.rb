class CalendarEntryType < ActiveRecord::Base
  belongs_to :calendar
  has_many :calendar_entries

  validates :name, :presence=>true, :length=>{:minimum=>2, :maximum=>199}
  validates :starts, :presence=>true
  validates :ends, :presence=>true

end
