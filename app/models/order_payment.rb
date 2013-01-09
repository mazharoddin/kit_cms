class OrderPayment < ActiveRecord::Base
 
  belongs_to :order
  belongs_to :user

  attr_accessor :sage_pay_results

  def self.load_from_sage_pay_response(system_id, crypt)
    results = {}
    dec = Order.sage_decrypt(system_id, crypt.gsub(' ', '+'))
    dec.split('&').each do |vv|
      n,v = vv.split('=')
      results[n] = v
    end
    ref = results["VendorTxCode"].split('-')
    order_id = ref[1]
    payment_id = ref[3]

    op = OrderPayment.sys(system_id).where(:id=>payment_id).first
    
    return nil if op.order_id.to_s != order_id.to_s

    op.sage_pay_results = results 
    return op
  end

  def update_from_sage_pay_results
    self.status = self.sage_pay_results["StatusDetail"]
    self.address_status = self.sage_pay_results["AddressResult"]
    self.postcode_status = self.sage_pay_results["PostCodeResult"]
    self.cv2_status = self.sage_pay_results["CV2Result"]
    self.threed_secure_status = self.sage_pay_results["3DSecureStatus"]
    self.card_identifier = self.sage_pay_results["Last4Digits"]
    self.card_type = self.sage_pay_results["CardType"]
    self.auth_code = self.sage_pay_results["TxAuthNo"]
    self.tx_id = self.sage_pay_results["VPSTxId"]
    self.processed_at = Time.now
    self.save

    self.order.status = self.sage_pay_results["Status"]
    self.order.save
  end

  
end

