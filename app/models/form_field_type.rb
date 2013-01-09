class FormFieldType < ActiveRecord::Base
  has_many :form_fields
  belongs_to :page_template_term, :dependent=>:delete
  has_many :user_attributes
  

  def long_name
    "#{name}: #{description}"
  end
end
