class Page < KitIndexed

  attr_accessible :full_path, :category_id, :status_id, :name, :title, :page_template_id, :created_by, :updated_by, :system_id, :tags, :meta_description, :meta_keywords, :header, :status, :needs_crawl, :updated_crawl

    @@index_def =  [
      {:name=>:id, :index=>:not_analyzed, :include_in_all=>false},
      {:name=>:system_id, :index=>:not_analyzed, :include_in_all=>false},
      {:name=>:name, :boost=>100, :user=>true},
      {:name=>:title, :boost=>50, :user=>true},
      {:name=>:tags, :boost=>20},
      {:name=>:full_path, :boost=>50},
      {:name=>:meta_description, :boost=>20, :user=>true},
      {:name=>:meta_keywords, :boost=>20, :user=>true},
      {:name=>:notes},
      {:name=>:terms, :as=>"concatenated_terms", :user=>true},
      {:name=>:created_by, :as=>"user.email"},
      {:name=>:updated_at, :type=>'date', :include_in_all=>false},
      {:name=>:status, :as=>"status.name", :index=>:not_analyzed},
      {:name=>:is_deleted, :index=>:not_analyzed},
      {:name=>:content, :as=>"concatenated_content(:current)", :user=>true},
      {:name=>:old_content, :as=>"concatenated_content(:old)", :include_in_all=>false},
      {:name=>:draft_content, :as=>"concatenated_content(:draft)", :include_in_all=>false},
      {:name=>:autosave_content, :as=>"concatenated_content(:autosave)", :include_in_all=>false}
      ]

    Page.do_indexing :Page, @@index_def 

    def self.index_def
      @@index_def
    end

    # this allows you to get block instances from the page. these block instances might have been eagrly loaded already (which they are in the most common case - i.e. rendering a page using the PageController). If they weren't loaded they will be when this is called, as they also will if you want something other than version 0
    def get_block_instances(instance_id, version = 0, field_name = nil, block_id = nil)
      if version==0
        r = []
        self.block_instances0.each do |block_instance|
          if field_name || block_id
            r << block_instance if block_instance.instance_id == instance_id && block_instance.field_name == field_name && block_instance.block_id == block_id
          else
            r << block_instance if block_instance.instance_id == instance_id
          end
        end
        return r
      else
        self.block_instances.where(:instance_id=>instance_id, :version=>version)
      end
    end

    def concatenated_terms
      self.terms.map { |term| term.value ? term.value.downcase : "" }.join(',')
    end

    def page_name
      (Preference.getCached(self.system_id, 'app_name') + self.full_path).gsub('/','_')
    end

    def is_readable_anon?
      self.category.is_readable_anon?
    end

    def old_content
      self.page_contents.where("version > 0")
    end

    def autosave_content
      self.page_contents.where(:version=>-2)
    end

    def draft_content
      self.page_contents.where(:version=>-1)
    end

    def current_content
      self.page_contents.where(:version=>0)
    end

    def concatenated_content(type = :current)
      method = type.to_s+"_content"
      if self.respond_to?(method)
        contents = self.send(method)
        contents.map {|c| c.value}.join(" ")
      else
        ""
      end
    end

    def self.published_status(sid)
      Status.published_status(sid)
    end

    belongs_to :page_template
    belongs_to :category
    belongs_to :status
    belongs_to :user, :class_name=>"User", :foreign_key=>"created_by"

    has_many :page_links
    has_many :comments
    has_many :block_instances, :dependent=>:destroy
    has_many :page_histories, :dependent=>:destroy
    
    has_many :block_instances0, :conditions=>"block_instances.version = 0", :class_name=>"BlockInstance"
    
    has_many :terms
    has_many :page_template_terms, :through=>:page_template

    has_many :page_contents, :dependent=>:destroy
    has_many :page_contents_version0, :conditions=>{:version => 0}, :class_name => "PageContent" 

    before_save { self.name.downcase! }
    before_save :history_start
    before_save :change_full_path
    
    after_save :history_end
    after_save :clear_cache

    after_destroy :clear_cache
    after_create :set_page_template_defaults

    validates_associated :page_template
    validates_presence_of :page_template, :unless => "self.status == Status.stub_status(self.system_id)"
    validates_presence_of :category_id
    validates_presence_of :status_id
    validates_associated :category
    validates :name, :format=>{:with=>/^[a-z0-9\-\.]+$/}, :presence=>true
    validates :title, :presence=>true
    validate :path_must_be_unique


    def full_url
      "#{Preference.get_cached(self.system_id, "host")}#{self.full_path}"
    end

    def queue_crawl
      self.needs_crawl = Time.now
      self.save
    end

    def self.do_crawl(sid)
      Page.sys(sid).where("needs_crawl is not null").find_each do |p|
        p.crawl
      end
    end

    def crawl(force = false)
      return unless force || self.needs_crawl 
      self.update_attributes(:needs_crawl=>nil)
      PageLink.delete_all("page_id = #{self.id}")
      
      logger.info "Crawling #{full_url}"
      Anemone.crawl(full_url, :depth_limit=>1) do |anemone|
        first_page = true
        anemone.on_every_page do |page|
          if first_page
            first_page = false
            next
          end

          uri = URI.parse(page.url.to_s)
          logger.info "Recording #{page.url.to_s}"
          PageLink.create(:page_id=>self.id, :url=>uri.path, :http_status=>page.code, :system_id=>self.system_id)
        end
      end
      self.update_attributes(:updated_crawl=>Time.now) 
    end      

    attr_writer :editable
    def editable
      @editable || false
    end

    attr_accessor :copy_of
    attr_accessor :draft
    attr_accessor :skip_history

    has_many :page_favourites, :dependent=>:destroy
    has_many :favourite_users, :through=>:page_favourites, :source=>"user"
    has_many :page_comments, :dependent=>:destroy
    has_many :page_edits, :dependent=>:destroy
    has_many :topic_threads, :through=>:page_threads
    has_many :page_threads, :dependent=>:destroy
    cattr_reader :per_page
    @@per_page = 10

    attr_accessor :page

    def generate_block_instances(user_id)
      # find any instances of:  = kit_editable_block(id, blah blah)
      self.page_template.body.scan(/= ?kit_editable_block\(\'?\"?([^\,\)\'\"]+)\'?\"?\s*,\s*\'?\"?([^\,\)\'\"]+)\'?\"?(?:\s*,\s*(\{.*\}))?\)/) do 
        self.generate_block_instance($1, $2, $3, user_id)
      end
    end

    def generate_block_instance(block_instance_id, block_id, param_options, user_id)
      if block_id.is_number?
        block = Block.find_sys_id(self.system_id, block_id)
      else

        block = Block.sys(self.system_id).where(:name=>block_id).first
      end

      if param_options == nil
        options = {}
      elsif param_options.instance_of?(String)
        options = eval(param_options)
      else
        options = param_options
      end

      bi = nil
      if options.size>0
        options.each do |name,value|
          bi = BlockInstance.create(:system_id=>self.system_id, :page_id=>self.id, :block_id=>block.id, :field_name=>name, :field_value=>value, :user_id=>user_id, :instance_id=>block_instance_id)
        end
      else
          bi = BlockInstance.create(:system_id=>self.system_id, :page_id=>self.id, :block_id=>block.id, :field_name=>'no_params', :field_value=>'no_params', :user_id=>user_id, :instance_id=>block_instance_id)
      end

      return bi
    end

    def clear_cache
      Category.clear_cache(self.system_id)
    end

    def path_must_be_unique
      full_path = make_full_path

      cnt = Page.sys(self.system_id).where(:full_path=>full_path).where(["id<>?", self.new_record? ? -1 : self.id]).count
      if cnt > 0
        errors.add(:name, "not unique within this category")
      end
    end

    def name_from_title
      self.title.urlise
    end

    def is_home_page?
      self.id.to_i == Preference.get(self.system_id, 'home_page').to_i rescue false
    end

    def make_home_page!
      PageHistory.record(self, nil, 'Made to be the home page', "")

      Preference.set(self.system_id, 'home_page', self.id, nil)
    end

    def Page.update_all_paths(sid)
      Page.sys(sid).find_each do |p|
        p.skip_history = true
        p.save!
      end
    end

    def clear_auto_save
      ActiveRecord::Base.connection.execute("delete from page_contents where version = -2 and page_id = #{self.id}")
    end    

    def stop_edit(user_id)
      PageEdit.delete_all(["page_id = ? and user_id = ?", self.id, user_id]) 
    end

    def change_full_path
      self.full_path = make_full_path
    end

    def by_id
      self.page = Page.find_sys_id(self.system_id, self.id)
      return self.page
    end

    def dif_template(is_mobile)
      if is_mobile && self.mobile_dif==1
        self.mobile_page_template
      else
        return self.page_template
      end
    end

    def mobile_page_template
      PageTemplate.where(:id=>self.page_template.mobile_version_id).first || self.page_template
    end

    def publish(user_id)
      self.status_id = Page.published_status(self.system_id).id
      self.publish_draft(user_id) if self.draft
      self.published_at = Time.now
      self.save
      PageHistory.record(self, user_id, 'Published', "")
    end

    def destroy_draft(user_id)
      self.page_contents.where(:version=>-1).each do |c|
        c.destroy
      end
      self.block_instances.where(:version=>-1).each do |bi|
        bi.destroy
      end
      PageHistory.record(self, user_id, 'Draft deleted', "")
    end

    def make_draft(user_id)
      self.page_contents.where("version=0").each do |content|
        PageContent.create(:system_id=>self.system_id, :page_id=>self.id, :field_name=>content.field_name,  :version=>-1, :value=>content.value, :user_id=>user_id)
      end

      BlockInstance.sys(self.system_id).where(:page_id=>self.id).where(:version=>0).each do |bi|
        BlockInstance.create(:system_id=>self.system_id, :page_id=>self.id, :field_name=>bi.field_name, :field_value=>bi.field_value, :version=>-1, :user_id=>user_id, :block_id=>bi.block_id, :instance_id=>bi.instance_id)
      end
      PageHistory.record(self, user_id, 'Draft created', "")
    end

    def publish_draft(user_id)
      self.page_contents.where("version <> -2").order("id desc").each do |pc|
        pc.version += 1
        pc.save
      end
      self.block_instances.where("version <> -2").order("id desc").each do |bi|
        bi.version += 1
        bi.save
      end
      PageHistory.record(self, user_id, 'Draft Published', "")
    end

    def recent_threads(count, user)
      level = user ? user.forum_level : 0

      self.topic_threads.limit(count).order("topic_threads.id desc").includes(:topic).where("topic_threads.is_visible = 1 and topics.is_visible = 1 and topics.read_access_level <= #{level}")
    end

    def link(mode='show', inplace_edit=false)
      if mode=='show'
        return self.full_path + (inplace_edit ? "?edit=1" : "")
      else
        return "/page/#{self.id}/#{mode}"
      end
    end

    def is_favourite?(user)
      user.is_favourite_page?(self)
    end

    def time_now
      Time.now
    end

    def history_start
      return if self.skip_history

      @new = self.new_record?
      @old_status_id = self.status_id_was
      @changes = self.changes
      @changed = self.changed
      if self.changed.include?("status_id")
        if self.status_id == Page.published_status(self.system_id)
          PageHistory.record(self, user_id, 'Published', "")
          self.published_at = Time.now
        elsif @old_status_id == Page.published_status(self.system_id)
          self.published_at = nil
          PageHistory.record(self, user_id, 'Unpublished', "")
        end
      end

    end

    def history_end
      return if self.skip_history

      if @new
        PageHistory.record(self, self.created_by, nil, 'New', 'Initial Creation', false)
        return
      end

      if @changes[:status_id] 
        old_status_name = Status.find(@old_status_id).name
        PageHistory.record(self, self.updated_by, 'Status changed', "From: #{old_status_name} To: #{self.status(true).name}")  
      end

      if @changes[:is_deleted]
        PageHistory.record(self, self.updated_by, 'Deleted status change', "Page is now #{self.is_deleted? ? 'deleted' : 'not deleted'}")
      end

      fields = [ ['name','Name'], ['full_path','Path'], ['tags','Tags'], ['meta_description', 'Meta Description'], ['meta_keywords', 'Meta Keywords'] ]

      fields.each do |field|
        if @changes[field[0].to_sym]
          from = @changes[field[1].to_sym][0] rescue ""

          PageHistory.record(self, nil, "#{field[1].to_sym} changed", "From: #{from}")
        end
      end
    end

    def self.mercury_region(field_type)
      if field_type=='text'
        return 'editable'
      elsif field_type=='line'
        return 'editable'
      else
        return 'editable'
      end
    end

    def is_stub?
      self.status_id == Status.stub_status(self.system_id).id
    end

    def is_published?
      self.status_id == Status.published_status(self.system_id).id
    end

    def deleted?
      self.is_deleted == 1
    end

    def self.children_of(category)
      Page.where(:category_id=>category.id).all
    end

    def make_full_path
      if self.category.parent_id == 0
        "/" + self.name
      else
        self.category.path + "/" + self.name
      end
    end

    def autotitle
      i = 1
      ok = false
      existing = Page.sys(self.system_id).where(:category_id => self.category_id).all
      until ok
        found = false
        existing.each do |p|
          if p.title == "Page #{i}"
            found = true
            break
          end
        end
        if found==false
          ok = true
        else
          i += 1
        end  
      end
      self.title = "Page #{i}"
    end

    def has_draft?
      self.page_contents.where("version < 0").count > 0
    end

    def render_field(name, version=0)
      value = load_field(name, version).value rescue nil

      return nil unless value
      begin
        value.gsub(/>\[(snippet|block)_([0-9]+)\/([0-9]+)\]</) do |snip|
          block_instance = self.get_block_instances("#{$1}_#{$2}").first
          block_instance.page = self
          r = block_instance ? block_instance.render : "[block missing '#{name}']"
          ">" + r + "<"
        end
      rescue Exception => e
        "[block error: #{e.message}]"
      end
    end

    def update_field(field_name, value, user=nil, field_title = nil, version = 0)
      old_value = load_field(field_name,version)
      return if old_value && value==old_value.value

      if version == 0
        ActiveRecord::Base.connection.execute("update page_contents set version = version + 1 where page_id = #{self.id} and field_name = '#{field_name}' and version >= 0") 
        field = PageContent.new
        field.system_id = self.system_id
        field.page_id = self.id
        field.version = 0
        field.field_name = field_name
      else
        field = PageContent.where(:page_id=>self.id, :version=>version, :field_name=>field_name).first
        if version==-2 && field==nil
          field = PageContent.new(:system_id=>self.system_id, :page_id=>self.id, :version=>version, :field_name=>field_name)
        end
      end
      field.value = value
      field.user_id = user.id if user
      field.save
      PageHistory.record(self,  user ? user.id : 0, "Updated#{version==-1 ? ' Draft' : ''} content", "'#{field_title}' changed", false, field.id) if version>=-1

    end

    def Page.field_values(sid, field_name,  page_template_ids = nil, only_published_and_visible = true, version = 0) 
      pcs = PageContent.where(:field_name=>field_name).where(:version=>version)
      pcs = pcs.joins(:page).where("pages.page_template_id in (#{page_template_ids.join ','})") if page_template_ids
      pcs = pcs.joins(:page).where("pages.is_deleted = 0 and pages.status_id = #{Page.published_status(sid).id}") if only_published_and_visible
      pcs.all.map { |pc| pc.value }
    end

    def Page.field_matches(sid, field_name, field_value,  page_template_ids = nil, only_published_and_visible = true, version = 0) 
      ps = Page
      ps = ps.where("pages.page_template_id in (#{page_template_ids.join ','})") if page_template_ids
      ps = ps.where("pages.is_deleted = 0 and pages.status_id = #{Page.published_status(sid).id}") if only_published_and_visible
      ps = ps.joins(:page_contents).where("page_contents.version = #{version}")
      ps = ps.where("page_contents.field_name = '#{field_name}'")
      pc_table = PageContent.arel_table
      ps = ps.where(pc_table[:value].eq(field_value))
      ps.all
    end

    def method_missing(meth, *args, &block)
      if meth.to_s =~ /^content_(.+)$/
        load_field($1, *args)
      elsif meth.to_s =~ /^value_(.+)$/
        load_field($1, *args).value
      else
        super
      end
    end

    def load_field(field_name, version=0)
      if version==0 #&& self.page_contents.loaded?
        self.page_content_version0(field_name) rescue nil
      else
        PageContent.where(:page_id=>self.id).where("version = #{version}").where("field_name = '#{field_name}'").first rescue nil
      end
    end

    def related_threads(count,user)
      self.recent_threads(count,user)
    end

    def menu_items
      MenuItem.sys(self.system_id).where(:link_url=>self.full_path).includes(:menu).joins(:menu).order("menus.name, menu_items.order_by")
    end

    def page_content_version0(field_name)
      self.page_contents_version0.each do |pc|
        return pc if pc.field_name == field_name
      end

      return nil
    end

    def copy_content_from(page) 
      page.page_contents.each do |pc|
        self.page_contents << pc.dup
      end
      page.block_instances.each do |ps|
        self.block_instances << ps.dup
      end
    end

    def copy_to(cat)
      page = self.dup
      page.category = cat
      page.change_full_path
      if page.save
        page.copy_content_from(self)
        return page.id
      else
        return nil
      end
    end

    def has_term_for(page_template_term)
      self.terms.where(:page_template_term_id=>page_template_term.id).count > 0
    end

    def term(term_name)
      Term.find_by_sql(["select t.* from terms t, pages p, page_template_terms pt where p.id = #{self.id} and p.page_template_id = pt.page_template_id and pt.name = ? and t.page_template_term_id = pt.id and t.page_id = p.id", term_name])       
    end

    def term_hierarchy(term_name)
      values = term(term_name)
      values.collect { |v|
        v.value.split(':') 
      }
    end


    def set_page_template_defaults
      self.skip_history = true
      self.allow_anonymous_comments = self.page_template.allow_anonymous_comments
      self.allow_user_comments = self.page_template.allow_user_comments
      self.save
      self.skip_history = false
    end

    def add_term(page_term, value)
      new_terms = []

      return new_terms if value == nil

      if value.instance_of?(String)
        new_terms << save_term(page_term, value) if value.not_blank?
      elsif value.instance_of?(HashWithIndifferentAccess)
        value.each do |name, val|
          new_terms << save_term(page_term, val) if val.not_blank?
        end  
      end

      return new_terms
    end      

    def save_term(page_term, value)
      new_term = Term.new
      new_term.page_template_term_id = page_term.id
      new_term.value = value
      new_term.metric = 0
      new_term.page_id = self.id
      new_term.system_id = self.system_id
      new_term.save
      return new_term
    end      
end
