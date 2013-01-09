include ActionView::Helpers::TextHelper

class Asset < GnricIndexed

  Asset.do_indexing :Asset, [
    {:name=>:id, :index=>:not_analyzed, :include_in_all=>false},
    {:name=>:file_file_name, :boost=>25},
    {:name=>:comment, :exclude_user=>true},
    {:name=>:tags, :boost=>20, :exclude_user=>true},
    {:name=>:system_id, :exclude_user=>true, :index=>:not_analyzed},
    {:name=>:code}
  ]

  has_many :gallery_assets
  has_many :galleries, :through=>:gallery_assets

  has_attached_file :file, :styles => {  :small => "300x300>", :large=>"800x800>", :medium=>"500x500", :thumb => "100x100" }

  def simple_url
    return "/file/#{self.id}/#{self.code}/#{self.file_file_name}"
  end

  def best_url(width, height) 
    biggest = width
    biggest = height if height>biggest
    if biggest>800
      self.url(:original)
    elsif biggest>500
      self.url(:large)
    elsif biggest>300
      self.url(:medium)
    elsif biggest>100
      self.url(:small)
    else
      self.url(:thumb)
    end
  end

  before_post_process :image?
  before_create :calculate_size

  before_save :maybe_rename_files
  before_save :update_code


  def update_code
    bits = self.file.url(:original).split('/')
    if image?
      self.code = bits[9]
    else
      self.code = bits[7]
    end
  end

  def Asset.fix_old
    Asset.order(:id).all.each do |asset|
      f = "#{Rails.root}/public/system/files/#{asset.id}/[0-9a-z]*"

      d = Dir.glob(f).first

      fn = d + "/original/#{asset.file_file_name}"

      if File.exist?(fn)
        image = File.new fn
        asset.file = image
        asset.save
      end

      image.close

    end
  end

  def nice_type
    self.file_content_type.split('/')[1] rescue self.file_content_type
  end

  def maybe_rename_files
    return if self.new_record?
    
    if self.file_file_name_changed?
      (self.file.styles.keys+[:original]).each do |style|
        path = self.file.path(style)
        begin
          FileUtils.move(path.gsub(self.file_file_name, self.file_file_name_was), File.join(File.dirname(path), self.file_file_name)) 
        rescue Exception => e
          logger.info "Renaming file failed (nothing to worry about): #{e.message}"
        end
      end
    end
  end
  
  def calculate_size  
    return unless image?   
     geo = Paperclip::Geometry.from_file(file.to_file(:original))
     self.height = geo.height
     self.width = geo.width
     self.is_image = 1
  end
  
  def image?
    (self.file_content_type == "image/jpeg" || self.file_content_type == "image/png" || self.file_content_type == "image/gif")
  end
  
  def self.image_types
    "'image/jpeg','image/gif','image/png'"
  end

  def url(size='original')
   file.url(size)
  end

  def file_path(size='thumb')
    url(size)
  end
  
  def sys_file_path(size="thumb")
    "public" + file_path(size)
  end

  def display_name(length = :full)
    n = self.file_file_name
    n ||= "file"
   
    len = 255
    len = 30 if length==:medium
    len = 10 if length==:short
    len = 80 if length==:long 
    truncate(n, :length=>len)
  end

  def serializable_hash(options = nil)
    options ||= {}
    options[:methods] ||= []
    options[:methods] << :url
    super(options)
  end

  def self.wild_search(search, _sid)
    assets = Asset
    table = Asset.arel_table
    fields = table[:file_file_name].matches("%#{search}%")
    fields = fields.or(table[:tags].matches("%#{search}%"))
    fields = fields.or(table[:comment].matches("%#{search}%"))
    assets.where(fields).sys(_sid)
  end

  def self.cache_key(sid, id, size)
    "asset_#{sid}_#{id}_#{size}"
  end

  def self.asset_tagged_url(sid, tag, size)
    Rails.cache.fetch(Asset.cache_key(sid, tag, size), :expires_in=>120.seconds, :race_condition_ttl=>5.seconds) do
      a = Asset.sys(sid).where("tags like '%#{tag}%'").order(:id).last
      if a
        a.file.url(size)
      else
        nil
      end
    end 
  end

  def self.asset_url(sid, id, size)
    Rails.cache.fetch(Asset.cache_key(sid, id, size), :expires_in=>120.seconds, :race_condition_ttl=>5.seconds) do
      a = Asset.find_sys_id(sid, id)
      if a
        a.file.url(size)
      else
        nil
      end
    end 
  end

  
end
