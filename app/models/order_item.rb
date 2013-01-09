class OrderItem < ActiveRecord::Base

  belongs_to :order
  belongs_to :orderable, :polymorphic=>true

  def get_total_price
    (self.unit_price * self.quantity) * ( 1 + self.tax_rate )
  end
end
