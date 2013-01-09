class Admin::TodoController < AdminController
  layout 'cms-boxed'

  def test
    
  end

  def create
    t = Todo.new(:name=>params[:todo][:name], :user_id=>current_user.id, :system_id=>_sid)
    t.save
    render :partial=>"/admin/todo/sidebar"
  end

  def search
    @page_num = params[:todo_page] || params[:todo_paginate] || 1

    @todos = Todo.sys(_sid).order("created_at desc")
    @todos = @todos.where("name like '%" + params[:for] + "%' or description like '%" + params[:for] + "%'") if params[:for]
    @todos = @todos.page(@page_num).per(20)

    if params[:todo_paginate]
      render :partial=>"/admin/todo/sidebar"
    else
      render "/admin/todo/search", :layout=>"cms-boxed"    
    end

  end

  def mark
    mode = params[:mode]
    id = params[:id]
    t = Todo.find_sys_id(_sid,id)
    if t
      if mode=="done" && t.closed_at==nil
        t.update_attributes(:closed_at=>Time.now)
        Activity.add(_sid, "Marked '#{t.name}' as done", current_user, "To do")
      elsif mode=="undone" && t.closed_at!=nil
        t.update_attributes(:closed_at=>nil)
        Activity.add(_sid, "Marked '#{t.name}' as not done", current_user, "To do")
      end
    end
    render :text=>"None", :layout=>false
  end
end
