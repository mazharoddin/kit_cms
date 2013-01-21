class CategoryController < KitController
  include ActionView::Helpers::JavaScriptHelper

  layout 'cms'
  protect_from_forgery :except => [:subcat]
  before_filter :can_use

  def all_cats
    @all_cats ||= Category.tree_by_depth(_sid)
  end

  @cat_tree = nil

  def make_tree(node)
    n = {}

    n[:t] = node.name
    n[:id] = node.id
    is_cat = node.instance_of?(Category)
    n[:d] = is_cat ? !node.is_visible : node.is_deleted?
    n[:y] = is_cat ? 'c' : ( node.is_stub? ? 's' : 'p' )
    n[:g] = node.tags unless is_cat
    n[:p] = node.full_path 
    n[:u] = node.status.name unless is_cat
    n[:b] = node.is_published? unless is_cat
    n[:k] = node.locked? unless is_cat

    if is_cat
      @cat_tree ||= Category.tree_with_children(_sid)
      this_cat = @cat_tree[node.id]
      n[:c] = []
      this_cat.parent_of.each do |child|
        n[:c] << make_tree(child)
      end
    end

    return n
  end

  def rename
    @message = ''
    okay = false

    category_id = params[:id]
    unless category_id
      render :js=>''
      return
    end

    category = Category.find_sys_id(_sid, category_id) rescue nil
    unless category 
      @message = "Can't find category to rename"
    else
      category.name = params[:name].urlise
        if category.save
          category.update_paths
          @message = "Category renamed"
          okay = true
        else
          @message = "Couldn't rename category. Names must be 1 to 200 in length, containing only letters, numbers, fullstops and hypens"
        end
    end

    render :json=>{:message=>@message, :okay=>okay, :name=>category.name}

  end

  def delete
    cat = Category.find_sys_id(_sid, params[:id])
    id = nil
    unless cat
      @message = "Cannot find category to delete"
    else
      if cat.children.count>0 || cat.documents.count>0
        id = nil
        @message = "Cannot delete category because it is not empty"
      else
        @message = "Category deleted"
        id = cat.id
        cat.destroy
      end
    end

    render :json=>{:message=>@message}
  end

  def move
    @message = ''
    copy = params[:mode]=='copy'

    source_id = params[:source_id]
    target_id = params[:target_id]

    if (source_id == target_id) 
      render :json=>{:message=>"Target matches source", :okay=>false}
      return
    end

    @is_cat = params[:is_cat]=="1"
    target_cat = Category.find_sys_id(_sid, target_id) rescue nil

    okay = false

    unless target_cat
      @message = "Can't find category to target"
      return
    end

    new_id = nil

    if @is_cat
      source_cat = Category.find_sys_id(_sid, source_id)
      unless source_cat
        @message = "Can't find category"
        return
      end

      if copy
        new_id = source_cat.copy_to(target_cat, true)
      else
        source_cat.make_child_of(target_cat)
      end
      @message = "Category #{copy ? 'copied':'moved'}"
      okay = true
    else
      page = Page.find_sys_id(_sid, source_id)
      unless page
        @message = "Can't find page"
        return
      end

      if copy
        new_id = page.copy_to(target_cat)
        if new_id
          @message = "Page copied"
          okay = true
        else
          @message = "A page with this name already exists in this category"
        end
      else
        page.category = target_cat
        if page.save      
          @message = "Page moved"
          okay = true
        else
          @message = "A page with this name already exists in this category"
        end
      end
    end

    Category.clear_cache(_sid)
    render :json => {:message=>@message, :okay=>okay, :new_id=>new_id}
  end

  def show
    @category = Category.find_sys_id(_sid, params[:id])
    render "show", :layout=>"cms"
  end

  def browse
    if params[:refresh]=="1"
      Rails.cache.delete(Category.cache_key(_sid))
    end

    json = Rails.cache.fetch(Category.cache_key(_sid)) do 
      json = make_tree(Category.root(_sid)).as_json 
    end

    render :json=>json
  end

  def new
    @category = Category.new
    @category.parent_id = params[:parent_id]
    @category.parent_id ||= 1
    if request.post?
      @category.is_readable_anon = true
      @category.system_id = _sid
      @category.name = params[:name].urlise
      if @category.save
        render :json=>{:okay=>true, :message=>"Category created", :id=>@category.id, :name=>@category.name}
      else
        errors = @category.errors.full_messages.join(', ')
        render :json=>{:okay=>false, :message=>"Could not save: " + errors }
      end
      return
    end
  end

  def create
    add_sid(:category)
    @category = Category.new(params[:category])
    @category.is_readable_anon = true
    if @category.save
      redirect_to "/pages?cat_id=#{@category.id}"
      return
    else
      render "new"
    end
  end

  def select_options
    if params[:search] && params[:search].length>0
      @categories = Category.sys(_sid).where("path like '%" + params[:search] + "%'")
    else 
      @categories = Category.sys(_sid).order('name').all
    end

    if @categories.size>0 
      html = render_to_string(:partial=>"select_options.html")

      render :js => "$('#page_category_id').html('#{html}'); $('#category_warning').html('');"
    else
      render :js => "$('#page_category_id').html(''); $('#category_warning').html('No match found');"
    end
  end

  def permissions
    @category = Category.find_sys_id(_sid, params[:id]) 
    if @category.is_root?
      flash[:alert] = "Can't change permissions of root category"
      redirect_to "/pages"
    end
    setup_permissions(@category.id)
  end  

  def permission_sub
    @category = Category.find_sys_id(_sid, params[:id])
    @category.copy_permissions_to_subs
    
    render :js=>"notify('Permissions copied to sub categories');"
  end

  def permission
    mode = params[:mode]
    group_id = params[:group_id].to_i
    category_id = params[:id].to_i
    granted = params[:granted]
    if granted=='true'
      if group_id==0
        Group.all.each {|g| grant_permission(category_id, g.id, mode)}
      else
        grant_permission(category_id, group_id, mode)
      end
    elsif granted=='false'
      if group_id==0
        Group.all.each {|g| revoke_permission(category_id, g.id, mode)}
      else
        revoke_permission(category_id, group_id, mode)
      end
    end
    permission_response(category_id) and return
  end

  def permission_response(category_id)
    Category.build_permission_cache(_sid)
    setup_permissions(category_id)
    read = escape_javascript(render_to_string(:partial=>"read_permissions"))
    write = escape_javascript(render_to_string(:partial=>"write_permissions"))
    render :js=>%Q|
      $('#read').html('#{read}'); 
      $('#write').html('#{write}');
      notify("Permission set");
    |
  end

  def grant_permission(category_id, group_id, mode)
      cg = CategoryGroup.sys(_sid).where(:category_id=>category_id).where(:group_id=>group_id).first
      unless cg
        cg = CategoryGroup.new(:system_id=>_sid, :category_id=>category_id, :group_id=>group_id)
      end
      if mode=='read'
        cg.can_read = 1
      elsif mode=='write'
        cg.can_write = 1
        cg.can_read = 1
      end
      cg.save
  end    

  def revoke_permission(category_id, group_id, mode)
      if mode=='read'
        CategoryGroup.delete_all(["system_id = ? and category_id = ? and group_id = ?", _sid, category_id, group_id])      
      else
        cg = CategoryGroup.sys(_sid).where(:category_id=>category_id).where(:group_id=>group_id).first
        if cg
          cg.can_write = 0
          cg.save
        end
      end
  end

  def permission_public
    @category = Category.find_sys_id(_sid, params[:id])
    @category.set_readable_anon(params[:public] == "1")

    permission_response(@category.id)
  end

  private
  def setup_permissions(category_id)
    @permissions = Category.permission_cache(_sid)[category_id]
    unless @permissions
      Category.build_permission_cache(_sid)
      @permissions = Category.permission_cache(_sid)[category_id]
    end
    @read_groups = {}
    Group.order(:name).all.collect { |g| @read_groups[g.id.to_i] = g.name }
    @write_groups = @read_groups.clone
    @category_id = category_id
    @category = Category.find_sys_id(_sid, category_id)
  end


end
