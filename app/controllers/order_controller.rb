class OrderController < GnricController
  layout "application"

  def sage_pay_failure
    @order_payment = process_sage_pay 
    @order_payment.order.order_items.each do |oi|
      oi.orderable.mark_unpaid
    end

    redirect_to Preference.get_cached(_sid, "url_after_failed_tickets_payment") || "/" if @order_payment
  end

  def sage_pay_success
    @order_payment = process_sage_pay 
    if @order_payment 
      @order_payment.order.order_items.each do |oi|
        @order_payment.order.status=='OK' ? oi.orderable.mark_paid(@order_payment) : oi.orderable.mark_unpaid
      end 
    end
    redirect_to Preference.get_cached(_sid, "url_after_successful_tickets_payment") || "/" if @order_payment
  end

  def pay_for_ads
     @ad = Ad.find_sys_id(_sid, params[:ad_id])
     redirect_to "/", :notice=>"Ad paying inconsistency" and return unless @ad.user_id == current_user.id

    redirect_to Preference.get_cached(_sid, "url_already_paid") if @ad.paid_at

    existing_items = @ad.order_items.first
    if existing_items
      @order = existing_items.order
      if @order.status=='OK'
        redirect_to Preference.get_cached(_sid, "url_already_paid")
        return
      end
    else
      @order = Order.new(params[:order])
      @order.system_id = _sid
      @order.user_id = current_user.id
      @order.description = "Online Ads"
      @order.country = 'GB'
      @order.status = "Unpaid"

      if @order.save 
        item = OrderItem.new
        item.name = "Ad '#{@ad.name}'"
        item.quantity = 1
        item.unit_price = @ad.price_paid
        item.total_price = @ad.price_paid
        item.tax_rate = @ad.tax_rate
        item.orderable = @ad
        item.order_id = @order.id
        item.system_id = _sid
        item.save
      end
    end 

    payment = OrderPayment.create(:order_id=>@order.id, :payment_type=>"SagePay", :system_id=>_sid, :user_id=>current_user.id, :ip_address=>request.remote_ip)
    @sagepay_crypt = @order.sagepay_crypt(payment.id)
    render "order/pay"
  end

  def pay_for_tickets
     @ticket_sale = TicketSale.find(params[:ticket_sale_id])
     redirect_to "/", :notice=>"Ticket selling inconsistency" and return unless @ticket_sale.user_id == current_user.id

    redirect_to Preference.get_cached(_sid, "url_already_paid") if @ticket_sale.paid_at

    existing_items = @ticket_sale.order_items.first
    if existing_items
      @order = existing_items.order
      if @order.status=='OK'
        redirect_to Preference.get_cached(_sid, "url_already_paid")
        return
      end
    else
      @order = Order.new(params[:order])
      @order.system_id = _sid
      @order.user_id = current_user.id
      @order.description = "Event Tickets"
      @order.country = 'GB'
      @order.status = "Unpaid"

      if @order.save 
        item = OrderItem.new
        item.name = "Ticket for '#{@ticket_sale.sellable.name}'"
        item.quantity = @ticket_sale.quantity
        item.unit_price = @ticket_sale.unit_price
        item.total_price = @ticket_sale.quantity * @ticket_sale.unit_price
        item.tax_rate = 0
        item.orderable = @ticket_sale
        item.order_id = @order.id
        item.system_id = _sid
        item.save
      end
    end 

    payment = OrderPayment.create(:order_id=>@order.id, :payment_type=>"SagePay", :system_id=>_sid, :user_id=>current_user.id, :ip_address=>request.remote_ip)
    @sagepay_crypt = @order.sagepay_crypt(payment.id)


    render "order/pay"
  end

  private 

  def process_sage_pay
    op = OrderPayment.load_from_sage_pay_response(_sid, params[:crypt])

    redirect_to "/", :notice=>"Incorrect response from payment gateway" and return nil unless op

    op.update_from_sage_pay_results

    return op
  end
end
