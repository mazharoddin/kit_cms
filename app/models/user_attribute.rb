class UserAttribute < ActiveRecord::Base
  has_many :user_attribute_values
  belongs_to :form_field_type

  validates_associated :form_field_type
  validates :name, :uniqueness=>{:scope=>:system_id}, :presence=>true, :length=>{:minimum=>1, :maximum=>200}
  validates :code_name, :exclusion=>{:in=>%w(id submit), :message=>"Illegal code name"}, :uniqueness=>{:scope=>:system_id}, :format=>{:with=>/^[a-z0-9\-\_]+$/i}
  
 
 
  
end

