class BlocksController < GnricController

  def index
    page = Page.sys(_sid).where(:id=>params[:page_id]).first
    blocks1 = Block.joins(:page_templates).where("page_template_id = #{page.page_template_id}").where("show_editors = 1").sys(_sid)
    blocks1 = blocks1.where("description like '%#demo%'") unless current_user && current_user.editor?
    blocks1 = blocks1.all
                 
    blocks2 = Block.where("all_templates=1 and show_editors=1").sys(_sid)
    blocks2 = blocks2.where("description like '%#demo%'") unless current_user && current_user.editor?
    blocks2 = blocks2.all

    blocks = blocks1 + blocks2
 
    @blocks = blocks.sort_by &:name

    render :layout=>false
  end

  def options
    @block = Block.where(:id=>params[:id]).first

    @fields = []

    @block.body.scan(/\[\[([^\:\]]+\:[^\:\]]+\:[^\]]+)\]\]/) do |field|
      @fields << field[0]
    end
    
    render :layout=>false
  end

  def preview_by_name
    @block = Block.sys(_sid).where(:name=>params[:name]).first
    if @block
      render :inline=>@block.render_preview(params[:options]), :layout=>false, :content_type=>"text/html"
    else
      render :text=>"#{params[:name]} not found"
    end
  end

  def show
    render :inline=>BlockInstance.sys(_sid).where(:page_id=>params[:page_id]).where(:instance_id=>params[:mercury_id]).first.render, :content_type=>"text/html"
  end

  def preview
    @block = Block.where(:id=>params[:id]).first

    if request.post?

    end

    render :inline=>@block.render_preview(params[:options]), :layout=>false, :content_type=>"text/html"
  end

  def store

    can_use unless params[:page_id].to_i==session[:trial_page_id].to_i

    @block = Block.find_sys_id(_sid, params[:id])
    @page = Page.find_sys_id(_sid, params[:page_id])
    params[:version] ||= "0"
    version = params[:version].to_i

    version = -1 if params[:draft]

    if version==0
      ActiveRecord::Base.connection.execute("update block_instances set version = version + 1 where page_id = #{@page.id} and instance_id = '#{params[:identity]}' and version >= 0")
    elsif version==-1
      ActiveRecord::Base.connection.execute("delete from block_instances where version = -1 and page_id = #{@page.id} and instance_id = '#{params[:identity]}' and system_id = #{_sid}")
    end 

    found_one = false
    first_instance_id = nil
    params["options"].each do |option_name, option_value|
      found_one = true
      bi = BlockInstance.create(:system_id=>_sid, :instance_id=>params[:identity], :page_id=>@page.id, :field_name=>option_name, :field_value=>option_value, :block_id=>@block.id, :user_id=>current_user ? current_user.id : 0, :version=>version )
      first_instance_id ||= bi.id
    end if params["options"]

    if found_one
      PageHistory.record(@page, current_user ? current_user.id : 0, "Updated#{version==-1 ? ' Draft' : ''} block", "Block '#{@block.name}'", false, 0, first_instance_id)
    else
      BlockInstance.create(:system_id=>_sid, :instance_id=>params[:identity], :page_id=>@page.id, :field_name=>"no_params", :field_value=>"no_params", :block_id=>@block.id, :user_id=>current_user ? current_user.id : 0, :version=>version).id
    end
    render :inline=>@block.render_preview(params[:options]), :layout=>false, :content_type=>"text/html"
  end

end
