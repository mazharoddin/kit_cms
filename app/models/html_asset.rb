class HtmlAsset < ActiveRecord::Base
  belongs_to :user
  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>80}
  before_save :generate_fingerprint

  attr_accessible :name, :file_type, :body, :system_id
  attr_accessor :compiled

  before_save :record_history

  def display_name
    full_type
  end

  def record_history
    if self.changed.include?('body') 
      DesignHistory.record(self)
    end
  end

  def history
    DesignHistory.sys(self.system_id).where(:model=>"HtmlAsset").where(:model_id=>self.id).order(:id)
  end

  def self.fetch(system_id, name, type)
    Rails.cache.fetch(HtmlAsset.cache_key(system_id, name.downcase, type), :expires_in=>5.minutes) do 
      asset = HtmlAsset.sys(system_id).where(:name=>name.downcase).where(:file_type=>type).first
      asset.write_to_file if asset
      asset
    end
  end

  def generate_fingerprint
    self.fingerprint = Digest::MD5.hexdigest("#{self.updated_at}-#{self.name}.#{self.file_type}")
  end
  
  def write_to_file
    parent = File.join(Rails.root, "public", "kit", self.file_type)
    FileUtils.mkdir_p(parent) unless File.exists?(parent)

    path = File.join(Rails.root, "public", "kit", self.file_type, self.kit_name)
    dir = File.join(Rails.root, "public", "kit", self.file_type)
    found = false
    Dir.glob(dir + "/#{self.name.downcase}*") do |f|
      if f==path
        found = true
      else
        File.delete(f)
      end
    end
    unless found
      self.generate_compiled unless self.compiled
      File.open(path, "w") { |f| f.write(self.compiled) }
    end
  end

  def kit_name
    "#{self.name.downcase}-#{self.fingerprint}.#{self.file_type}".downcase
  end

  def generate_compiled
    if self.file_type=='css'
      self.generate_css
    elsif self.file_type=='js'
      self.generate_js 
    else
      self.compiled = self.body
    end
  end

  def generate_css
      self.compiled = Sass::Engine.new(self.body, :syntax=>:scss, :style=>Rails.env=='development' ? :expanded : :compressed).to_css

      return self
  end

  def generate_js
    self.compiled = self.body

    return self
  end

  def self.cache_key(system_id, name, type)
    "kit_htmlasset_#{name.downcase}.#{system_id}.#{type}"
  end

  def self.clear_cache(asset)
    Rails.cache.delete(HtmlAsset.cache_key(asset.system_id, asset.name, asset.file_type))
  end

  def self.default_body(type)
    if type == 'css'
%Q[
/* Sassy CSS Stylesheet Examples - can use normal CSS3, but also: */

$var: #123;
$big: 12px;

.example {
  color: $var;
  span: {
    font-size: $big;
  }
}

.more-example {
  @extend .example;
  background-color: #000;
}

@mixin left_with_margin($m) {
  float: left;
  margin: $m;
}

#data {
  @include left_with_margin(10px);
}
]
    elsif type == 'js'
      %Q[
// Javascript 
]
    else
      ""
    end
  end

  def self.create_default(sid, user_id, type)
    asset = HtmlAsset.new
    asset.system_id = sid
    asset.file_type = type
    asset.name = 'application'
    asset.body = HtmlAsset.default_body(type)
    asset.user_id = user_id
    asset.save
  end

  def full_type
    if file_type=='js'
      "Javascript"
    elsif file_type=='css'
      "Stylesheet"
    else
      "Unknown"
    end
  end
end
