class MenuController < AdminController

  layout "cms"

  def new
    @menu = Menu.new
  end

  def create
    @menu = Menu.new(params[:menu])
    @menu.system_id = _sid

    if @menu.save
      redirect_to "/menus", :notice=>"New menu created"
      Activity.add(_sid, "Created menu '#{@menu.name}'", current_user.id, "Menu")
      return
    else
      render "new"
    end
  end


  def edit
    @menu = Menu.where(:system_id=>_sid).where(:id=>params[:id]).first
    @menu.flush
    @menu_item = MenuItem.find_sys_id(_sid, params[:item_id])

    render "show"
  end

  def index
    @menus = Menu.sys(_sid).order(:name).all

  end

  def show
    @menu = Menu.where(:system_id=>_sid).where(:id=>params[:id]).first

    @menu_item = MenuItem.new
  end

  def promote
    @menu = Menu.sys(_sid).where(:id=>params[:id]).first
    if params[:parent_id]
      params[:item_id] =~ /^i_(\d+)$/
      mi = MenuItem.find_sys_id(_sid, $1)
      mi.parent_id = params[:parent_id]
      mi.save 
    end
    Menu.where(:id=>params[:id]).first.flush
    Activity.add(_sid, "Updated menu '#{@menu.name}'", current_user.id, "Menu")
    redirect_to "/menu/#{params[:id]}"
  end
  
  def move
    @menu = Menu.where(:system_id=>_sid).where(:id=>params[:id]).first
    seq = 0
    previous_parent_id = nil
    params[:order].split('&').each do |o|
      next if o.is_blank? 
      seq += 1
      key,value = o.split('=')

      if key =~ /^tree\[i_(\d+)\]\[undefined\]$/
        key = 'tree[]'
        value = "i_" + $1
      end
      
      logger.debug "#{key}  =  #{value}"

      value =~ /^i_(\d+)$/
      id = $1
      if key =~ /^tree\[i_(\d+)\]\[\]$/
        parent_id = $1.to_i
        logger.debug "#{parent_id} => #{id}"
        if parent_id != previous_parent_id
          MenuItem.sys(_sid).where(:id=>parent_id).first.update_attributes(:order_by => seq, :parent_id=>0) if parent_id.to_i < 1000000
          seq += 1
          previous_parent_id = parent_id
        end
        MenuItem.sys(_sid).where(:id=>id).first.update_attributes(:order_by=>seq, :parent_id=>parent_id) if id.to_i < 1000000
      else
        MenuItem.sys(_sid).where(:id=>id).first.update_attributes(:order_by=>seq, :parent_id=>0) if id.to_i < 1000000
      end 
    end
    Activity.add(_sid, "Updated menu '#{@menu.name}'", current_user.id, "Menu")
    @menu.flush
    render :js=>"$('#message').html('Saved changes');" 
  end

  def delete_item
    @menu_item = MenuItem.sys(_sid).where(:id=>params[:id]).first
    @menu = @menu_item.menu
    Activity.add(_sid, "Removed '#{@menu_item.name}' from menu '#{@menu.name}'", current_user.id, "Menu")
    @menu_item.menu.flush
    @menu_item.destroy
    redirect_to request.referrer 
  end

  def delete
    @menu = Menu.sys(_sid).where(:id=>params[:id]).first
    Activity.add(_sid, "Deleted menu '#{@menu.name}'", current_user.id, "Menu")
   @menu.flush
   @menu.destroy
  redirect_to "/menus"
  end

  def add
    @menu = Menu.sys(_sid).where(:id=>params[:id]).first
    @menu.flush
      
    params[:menu_item][:parent_id] = 0 if params[:menu_item][:parent_id].is_blank?

    if request.post?
      @menu_item = MenuItem.new
      @menu_item.menu_id = @menu.id
      @menu_item.parent_id = 0
      @menu_item.order_by = MenuItem.count + 1
      @menu_item.link_url = '/'
      @menu_item.system_id = _sid
    elsif request.put?
      @menu_item = MenuItem.sys(_sid).where(:id=>params[:item_id]).first
    end

    if @menu_item.update_attributes(params[:menu_item]) 
      Activity.add(_sid, "Added '#{@menu_item.name}' to menu '#{@menu.name}'", current_user.id, "Menu")
      redirect_to "/menu/#{@menu.id}"
      return
    else
      render "show"
    end

  end

  private


end
