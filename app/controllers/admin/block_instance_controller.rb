class Admin::BlockInstanceController < AdminController

  def index
    @blocks = BlockInstance.includes(:block, :page).order("instance_id, version").sys(_sid)
    if params[:block_id]
      @blocks = @blocks.where(:block_id=>params[:block_id])
      @block = Block.find_sys_id(_sid,params[:block_id])
    else
      params[:page_id] ||= "0"
      @page = Page.where(:id=>params[:page_id].to_i).sys(_sid).first unless params[:page_id]=="0"
      @blocks = @blocks.where(:page_id=>params[:page_id]).order("block_id, version")
      @blocks = @blocks.where("version = 0") unless params[:showall]
    end 
    @blocks = @blocks.page(params[:page]).per(50)
  end

  def show
    @instance = BlockInstance.where(:page_id=>params[:page_id]).where(:id=>params[:id]).sys(_sid).where(:version=>params[:version] || 0).first
    if @instance
      @block = @instance.block
      @options = BlockInstance.where(:page_id=>params[:page_id]).where(:version=>@instance.version).where(:instance_id=>@instance.instance_id).sys(_sid).all
    end
  end

  def create
    instance = BlockInstance.new
    instance.system_id = _sid
    instance.page_id = 0
    instance.block_id = params[:id]
    instance.instance_id = rand(100000000000000000)
    instance.field_name = 'no_params'
    instance.field_value = 'no_params'
    instance.user_id = current_user.id
    instance.save
    instance.update_attributes(:instance_id=>"instance_#{instance.id}")
 
    redirect_to "/admin/block_instance/#{instance.id}/edit"
  end

  def update
    @instance = BlockInstance.sys(_sid).where(:version=>params[:version]).where(:id=>params[:id]).first

    @block = @instance.block
   # BlockInstance.delete_all(["instance_id = ? and version = ? and page_id = ?", @instance.instance_id, params[:version], params[:page_id]])
    b = nil

    instance_id = params[:instance_name]
    @errors = []


    params[:options].each do |name, value|
      b = BlockInstance.sys(_sid).where(:block_id=>@block.id).where(:page_id=>params[:page_id]).where(:field_name=>name).where(:instance_id=>instance_id).where(:version=>params[:version]).first
      if b
        @errors << b.errors unless b.update_attributes(:field_value=>value)
      end
    end if params[:options]
    
    if b == nil
      b = BlockInstance.sys(_sid).where(:block_id=>@block.id).where(:page_id=>params[:page_id]).where(:field_name=>'no_params').where(:instance_id=>instance_id).where(:version=>params[:version]).first
      if b
        @errors << b.errors unless b.update_attributes(:field_value=>'no_params')
      end
    end      
     
    redirect_to "/admin/block_instance/#{b.id}?page_id=#{@instance.page_id}&version=#{params[:version]}"
  end

  def edit
    @instance = BlockInstance.sys(_sid).where(:id=>params[:id]).first
    @block = @instance.block
    @options = BlockInstance.where(:version=>@instance.version).where(:instance_id=>@instance.instance_id).all

    @fields = []
    @block.body.scan(/\[\[([^\]]+)\]\]/) do |field|
      @fields << field[0]
    end

    @options.each do |option|
      params[:options] ||= {}
      params[:options][option.field_name] = option.field_value
    end
  end

end
