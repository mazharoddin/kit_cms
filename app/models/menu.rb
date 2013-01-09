class Menu < ActiveRecord::Base
  has_many :menu_items, :order=>"order_by"


  def top_level_items
    r = []
    self.menu_items.each do |item|
      r << item if item.parent_id = 0
    end
    return r
  end

  def add_page(page, name=nil, parent_id = 0)
    mi = MenuItem.new
    mi.parent_id = parent_id
    mi.name = name || page.title
    mi.link_url = page.full_path
    mi.title = page.title
    mi.menu_id = self.id
    mi.order_by = self.menu_items.count + 1
    mi.system_id = self.system_id
    mi.save
  end

  def flush
    Rails.cache.delete(Menu.cache_key(self.system_id, self.name))
  end

  def Menu.cache_key(sid, name)
    "_menu_#{sid}_#{name.downcase}"
  end
end

