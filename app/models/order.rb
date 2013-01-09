class Order <  ActiveRecord::Base

  has_many :order_items
  belongs_to :user
  has_many :order_payments, :order=>"created_at desc"

  def display_address
    d = []
    d << self.address1 unless self.address1.is_blank?
    d << self.address2 unless self.address2.is_blank?
    d << self.town unless self.town.is_blank?
    d << self.postcode unless self.postcode.is_blank?
    d << self.country unless self.country.is_blank?

    d.join(", ")
    
  end

  def reference(payment_id)
    "kit-#{self.id}-#{rand(10000000)}-#{payment_id}" 
  end

  def sagepay_crypt(payment_id)
    data = {}
    o = self
    data["VendorTxCode"] = reference(payment_id)
    data["Amount"] = self.order_items.inject(0) { |sum, oi| sum = sum + oi.total_price }
    data["Currency"] = "GBP"
    data["Description"] = self.description
    data["SuccessURL"] = Preference.get_cached(self.system_id, 'host') + "/order/sp/success"
    data["FailureURL"] = Preference.get_cached(self.system_id, 'host') + "/order/sp/failure"
    data["CustomerEMail"] = self.email
    data["VendorEMail"] = Preference.get_cached(self.system_id, 'sage_pay_order_payment_email')
    data["BillingSurname"] = o.lastname
    data["BillingFirstnames"] = o.firstname
    data["BillingAddress1"] = o.address1
    data["BillingAddress2"] = o.address2 if o.address2
    data["BillingCity"] = o.town
    data["BillingPostCode"] = o.postcode
    data["BillingCountry"] = o.country || "UK"
    data["DeliverySurname"] = o.lastname
    data["DeliveryFirstnames"] = o.firstname
    data["DeliveryAddress1"] = o.del_address1 || o.address1
    data["DeliveryAddress2"] = o.del_address2 || o.address2
    data["DeliveryCity"] = o.del_town || o.town
    data["DeliveryPostCode"] = o.del_postcode || o.postcode
    data["DeliveryCountry"] = o.del_country || o.country
    basket = []
    basket << o.order_items.size.to_s
    o.order_items.each do |i|
      basket << i.name
      basket << i.quantity
      basket << i.unit_price
      basket << i.tax_rate
      basket << i.unit_price * ( 1 + i.tax_rate )
      basket << i.total_price
    end
    data["Basket"] = basket.join(':')

    dataa = []
    data.each do |name,value|
      dataa << "#{name}=#{value}"
    end
    datas = dataa.join('&')
    Base64.strict_encode64(Order.sage_encrypt_xor(datas, Preference.get_cached(self.system_id, 'sage_pay_encryption_key')))
  end

  def self.sage_decrypt(system_id, ciphertext)
    sage_encrypt_xor(Base64.decode64(ciphertext), Preference.get_cached(system_id, 'sage_pay_encryption_key'))
  end

  def self.sage_encrypt_salt(min, max)
    length = rand(max - min + 1) + min
    SecureRandom.base64(length + 4)[0, length]
  end

  def self.sage_encrypt_xor(data, key)
    raise 'No key provided' if key.blank?

    key *= (data.bytesize.to_f / key.bytesize.to_f).ceil
    key = key[0, data.bytesize]

    data.bytes.zip(key.bytes).map { |b1, b2| (b1 ^ b2).chr }.join
  end

end
