class Stylesheet < ActiveRecord::Base
  belongs_to :user
  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>80}

  attr_accessor :css
  attr_accessor :fingerprint

  def self.fetch(system_id, name)
    Rails.cache.fetch(Stylesheet.cache_key(system_id, name.downcase)) do 
      sheet = Stylesheet.sys(system_id).where(:name=>name.downcase).first
      sheet.generate_css if sheet
      sheet
    end
  end

  def gnric_name
    "#{self.name.downcase}-#{self.fingerprint}.css".downcase
  end

  def generate_css
      self.css = Sass::Engine.new(self.body, :syntax=>:scss, :style=>Rails.env=='development' ? :expanded : :compressed).to_css
      self.fingerprint = Digest::MD5.hexdigest("#{Time.now}-#{self.id}")

      return self
  end

  def self.cache_key(system_id, name)
    "gnric_stylesheet_#{name.downcase}-#{system_id}"
  end

  def self.default_body 
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

  end

  def self.create_default(sid, user_id)
    Stylesheet.create(:system_id=>sid, :user_id=>user_id, :name=>"application", :body=>Stylesheet.default_body)
  end

end
