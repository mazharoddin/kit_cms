class Layout < ActiveRecord::Base
  store_templates

  use_kit_caching

  before_save :make_path
  before_save :set_format
  has_many :page_templates
  has_many :views
  belongs_to :user

  before_save :record_history

  validates :format, :presence=>true
  validates :locale, :presence=>true
  validates :name, :presence=>true
  validates :handler, :presence=>true

  def display_name
    "Layout"
  end

  def record_history
    if self.changed.include?('body')
      DesignHistory.record(self)
    end
  end

  def history
    DesignHistory.sys(self.system_id).where(:model=>"Layout").where(:model_id=>self.id).order("id desc")
  end
  
  def make_path
    self.path = "layouts/" + self.name.urlise 
  end

  def set_format
    self.format = 'html'
  end

  def locale_enum
    ['en']
  end

  def handler_enum
    ['haml', 'erb', 'builder']
  end

  def self.name_exists?(name)
    Layout.where("name = '#{name}'").count > 0
  end

  def self.create_default(sid, user_id)
    layout = Layout.new(:stylesheets=>"application", :javascripts=>"", :path=>"layouts/application", :handler=>"haml", :format=>"html", :locale=>"en", :system_id=>sid, :user_id=>user_id, :name=>"application-#{sid}", :body=><<eos
!!!
%html
  / Layout: application-#{sid}
  %head
    = render :partial=>"layouts/gnric_header"
    %style(type="text/css")
      div#edit_link { top:30px; }
  %body
    = yield
eos
  )

    layout.save!
  end
end
