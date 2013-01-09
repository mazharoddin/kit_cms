class Admin::OrderController < AdminController

  def index
    @orders = Order.sys(_sid).order("orders.created_at desc")

    @orders = @orders.where(["orders.postcode = ?", params[:postcode]]) if params[:postcode].not_blank? 
    @orders = @orders.where(["orders.firstname = ? or orders.lastname = ? or orders.email like '%#{params[:user]}%'", params[:user], params[:user]]) if params[:user].not_blank?
    @orders = @orders.where(:id=>params[:order_id]) if params[:order_id].not_blank? 

    @orders = @orders.joins(:order_items).where("order_items.name like '%#{params[:description]}%' or orders.description like '%#{params[:description]}%'") if params[:description].not_blank?
    @orders = @orders.joins(:order_payments).where(["order_payments.tx_id = ?", params[:tx_id]]) if params[:tx_id].not_blank?
    @orders = @orders.joins(:order_payments).where(["order_payments.card_identifier = ?", params[:card_identifier]]) if params[:card_identifier].not_blank?
    @orders = @orders.includes([:user, :order_items, :order_payments]).page(params[:page]).per(25)
  end

  def payment
    @payment = OrderPayment.sys(_sid).where(:id=>params[:id]).first
  end

  def show
    @order = Order.sys(_sid).where(:id=>params[:id]).first
  end
end
