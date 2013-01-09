class CalendarEntry < ActiveRecord::Base

  has_many :ticket_sales, :as=>:sellable

  geocoded_by :position
  after_validation :geocode
  belongs_to :calendar
  belongs_to :user
  belongs_to :location
  belongs_to :calendar_entry_type

  accepts_nested_attributes_for :location, :allow_destroy=>false

  has_attached_file :image, :styles=>{:medium=>"300x300", :thumb=>"100x100"}

  validates_associated :location

  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>200}
  validates :start_date, :presence=>true
  validates :end_date, :presence=>true

  def list_days(sep = ' ')
    d = []
    d << "Sun" if self.on_0==1
    d << "Mon" if self.on_1==1
    d << "Tue" if self.on_2==1
    d << "Wed" if self.on_3==1
    d << "Thu" if self.on_4==1
    d << "Fri" if self.on_5==1
    d << "Sat" if self.on_6==1
    return d.join(sep)
  end

  def on_day(n)
    return self.send("on_#{n}")
  end

  def no_days
    return self.on_0  + self.on_1 + self.on_2 + self.on_3 + self.on_4 + self.on_5 + self.on_6 == 0
  end

  def in_future?
    the_date = self.end_date || self.start_date
    return the_date>Date.today
  end


  def date_display
    dd = []
    dd << self.start_date.to_formatted_s(:rfc822)
    dd << self.start_time.to_formatted_s(:time) if self.start_time
    
    if self.start_date != self.end_date
      dd << "to"
      dd << self.end_date.to_formatted_s(:rfc822)
      dd << self.end_time.to_formatted_s(:time) if self.end_time
    end

    dd.join(' ')
  end

  def position
    self.location.display
  end


  def has_image?
    self.image.file?
  end

  def url
    "#{self.start_date.to_formatted_s.urlise}/#{self.id}-#{self.name.urlise}"
  end

end
