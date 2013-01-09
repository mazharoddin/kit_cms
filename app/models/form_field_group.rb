class FormFieldGroup < ActiveRecord::Base
  belongs_to :form
  has_many :form_fields, :order=>:display_order
end
