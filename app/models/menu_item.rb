class MenuItem < ActiveRecord::Base

  belongs_to :parent, :class_name=>"MenuItem"
  has_many :children, :foreign_key=>"parent_id", :class_name=>"MenuItem", :order=>:order_by
  belongs_to :menu
  validates :name, :length=>{:minimum=>1, :maximum=>200}
  validates :link_url, :length=>{:minimum=>1, :maximum=>200}
  after_save :flush_parent_menu_cache

  def flush_parent_menu_cache
    self.menu.flush
  end


  def child_is_current(url)
    self.children.each do |child|
      return true if child.link_url==url
    end

    return false
  end

  def has_children?
    children.size>0
  end
end
