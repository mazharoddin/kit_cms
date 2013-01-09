module PagesHelper

  
  def list_name(page, len, with_path = false)
    return (with_path ? page.full_path : page.name).right_truncate(len) + (current_user.is_favourite_page?(page) ? "*" : "")
  end


end
