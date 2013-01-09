module OrderHelper

  def pay_for_tickets(ticket_sales_id, options = {})
    begin
      return "pay form will appear here" unless ticket_sales_id 
      @ticket_sale = TicketSale.find(ticket_sales_id)
      return "invalid user" unless @ticket_sale.user_id == current_user.id
      
      return "These tickets have already been paid for" if @ticket_sale.paid_at
      @order = Order.new
      @order.email = current_user.email
      @order.firstname = @ticket_sale.firstname
      @order.lastname = @ticket_sale.lastname

      gnric_render :partial=>"order/pay_for_tickets", :locals=>{:options=>options}
    rescue Exception => e
      e.message
    end
  end
end
