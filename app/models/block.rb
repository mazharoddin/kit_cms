class Block < ActiveRecord::Base
  has_and_belongs_to_many :page_templates


  attr_accessible :name, :show_editors, :all_templates, :page_template_ids, :description, :body, :system_id, :user_id
  validates :name, :presence=>true, :length=>{:minimum=>1, :maximum=>80}
  belongs_to :user

  use_kit_caching

  before_save :record_history

  def display_name
    "Block"
  end

  def record_history
    if self.changed.include?('body')
      DesignHistory.record(self)
    end
  end

  def history
    DesignHistory.sys(self.system_id).where(:model=>"Block").where(:model_id=>self.id).order("id desc")
  end

  def self.ensure(sid, name, body, page_template_id = nil, show_editors = false, description = '')

    return if Block.where(:name=>name).sys(sid).count>0

    b = Block.new
    b.system_id = sid
    b.name = name
    b.description = description
    b.body = body
    b.show_editors = show_editors
    b.save
  end

  def render_preview(options)
    begin
      self.body.gsub(/\[\[([^\:]+)\:([^\:]+)\:[^\]]+\]\]/) do
        if $2=="friendly"
          options[$1].friendly_format
        else 
          options[$1]
        end
      end
    rescue Exception => e
      logger.error(e)
      "[block error #{e.message}]"
    end
  end 
end
