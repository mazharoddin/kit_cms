class TicketSale < ActiveRecord::Base    

  belongs_to :user
  belongs_to :sellable, :polymorphic=>true 
  has_many :order_items, :as=>:orderable

  def mark_paid(payment)
    self.payment_reference = payment.order.reference(payment.id)
    self.paid_at = Time.now
    self.save
  end

  def mark_unpaid
    self.paid_at = nil
    if self.sellable_type=='CalendarEntry'
      self.sellable.tickets_remaining += self.quantity
      self.sellable.save
    end
    self.save
  end
end
