module AdminHelper
 
  @done_right_column = false

  def right_column(sections=nil)
    return if @done_right_column
    @done_right_column = true
    content_for(:right, render(:partial=>"admin/shared/right_column", :locals=>{:sections=>sections}))
  end
end
