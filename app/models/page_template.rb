class PageTemplate < ActiveRecord::Base
  has_many :page_template_html_asset
  has_many :html_assets, :through=>:page_template_html_asset

  has_many :pages
  belongs_to :layout
  has_and_belongs_to_many :blocks
  has_many :views
  has_many :page_template_terms
  belongs_to :user

  attr_accessible :name, :template_type, :layout_id, :allow_anonymous_comments, :allow_user_comments, :hidden, :is_mobile, :mobile_version_id, :body, :system_id, :html_asset_ids, :header, :footer, :is_default, :page_type

  use_kit_caching

  before_validation :set_page_type

  belongs_to :mobile_version, :class_name=>"PageTemplate", :foreign_key=>"mobile_version_id"
  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>40}
  validates :page_type, :presence=>true, :length=>{:minimum=>1, :maximum=>100}, :format=>{:with=>/[a-z0-9\.\_\-]+/}

  validates :layout_id, :presence=>true
  validates_associated :layout

  before_save :record_history


  def term(name)
    self.page_template_terms.each do |ptt|
      return ptt if ptt.name.urlise == name.urlise
    end
    return nil
  end

  def self.get_custom_template(sid, name, request, search_name_only = false)  
    t = nil

    t = PageTemplate.load_template(sid, "Kit/#{name}") if name.instance_of?(String) && name.not_blank? 
    return t if t
    return t if search_name_only

    t = PageTemplate.load_template(sid, "Kit#{request.fullpath}")
    return t if t
    t = PageTemplate.load_template(sid, "Kit/#{request.params[:controller]}/#{request.params[:action]}")
    return t if t
    t = PageTemplate.load_template(sid, "Kit/#{request.params[:controller]}")
    return t
  end    

  def self.load_template(sid, name)
    PageTemplate.load(sid, name)
  end
  
  def display_name
    "Page Template"
  end

  def record_history
    if self.changed.include?('body') || self.changed.include?('header') || self.changed.include?('footer')
      DesignHistory.record(self)
    end
  end
  
  def history
    DesignHistory.sys(self.system_id).where(:model=>"PageTemplate").where(:model_id=>self.id).order(:id)
  end
  
  def PageTemplate.load(sid, name)
    Rails.cache.fetch("page_template_#{sid}_#{name}", :expires_in=>15.seconds) do
      PageTemplate.sys(sid).where(:name=>name).first 
    end
  end

  def set_page_type
    unless self.page_type
      self.page_type = self.name.urlise
    end
  end

  def  template_type_enum
    ['erb', 'haml', 'builder']
  end

  def has_mobile_version?
    self.mobile_version_id != 0
  end

  def self.create_default(sid, user_id)
    PageTemplate.create(:system_id=>sid, :header=>'', :footer=>'', :layout_id=>Layout.sys(sid).first.id, :template_type=>"haml", :is_mobile=>0, :is_default=>1, :page_type=>"default", :name=>"default", :body=>"= field('body')")
  end

  def javascripts
    self.html_assets.where(:file_type=>"js").all
  end

  def stylesheets
    self.html_assets.where(:file_type=>"css").all
  end
end
