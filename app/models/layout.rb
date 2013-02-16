class Layout < ActiveRecord::Base
  has_many :html_assetable, :as=>:html_assetable
  has_many :html_assets, :through=>:html_assetable

  store_templates

  use_kit_caching

  attr_accessible :name, :handler,  :body, :html_asset_ids, :path, :format, :locale, :system_id, :user_id
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
    self.path = "layouts/#{self.system_id}/#{self.name.urlise}"
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

  def self.name_exists?(sid, name)
    Layout.sys(sid).where("name = '#{name}'").count > 0
  end

  def self.create_default(sid, user_id)
    layout = Layout.new(:path=>"layouts/#{sid}/application", :handler=>"haml", :format=>"html", :locale=>"en", :system_id=>sid, :user_id=>user_id, :name=>"application", :body=><<eos
!!!
%html
  / Layout: application [#{sid}]
  %head
    = render :partial=>"layouts/kit_header"
    %style(type="text/css")
      div#edit_link { top:30px; }
  %body
    = yield
eos
  )

    layout.save!
  end

  def javascripts
    self.html_assets.where(:file_type=>"js").all
  end

  def stylesheets
    self.html_assets.where(:file_type=>"css").all
  end
  
  def old_stylesheets
    self.read_attribute(:stylesheets)
  end

  def old_javascripts
    self.read_attribute(:javascripts)
  end

  def self.preference(sid, name)
    l = Layout.sys(sid).where(:id=>Preference.get_cached(sid, name)).first rescue nil
    return l if l
    Layout.sys(sid).order("created_at").first
  end

end
