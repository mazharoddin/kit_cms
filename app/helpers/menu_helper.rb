module MenuHelper
  def get_last_node(menu)
    menu.menu_items.reverse.each do |m|
      return m if m.parent_id == 0
    end
  end


  def is_multilevel?(menu)
    menu.menu_items.each do |m|
      return true if m.parent_id != 0
    end

    return false
  end

end


