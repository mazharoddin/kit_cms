class FormField < ActiveRecord::Base
  belongs_to :form
  belongs_to :form_field_type
  belongs_to :form_field_group
 
  before_create :set_name 
  before_create :set_code_name

  validates :name, :uniqueness=>{:scope=>:form_id}, :presence=>true,  :length=>{:minimum=>1, :maximum=>200}
  validates :form_field_type, :presence=>true
  validates_associated :form_field_type
  validates :code_name, :exclusion=>{:in=>%w(id submit), :message=>"Illegal code name"}, :uniqueness=>{:scope=>:form_id}, :format=>{:with=>/^[a-z0-9\-\_]+$/i}

  def field_type
    self.form_field_type.field_type
  end

  def set_name
    self.name = generate_unique_name("name")
  end

  def set_code_name
    self.code_name = self.name.urlise
    if self.code_name == "id" || self.code_name == "submit"
      self.code_name = "field_#{self.code_name}"
    end
    self.code_name = generate_unique_name("code_name")
  end

  private

  def generate_unique_name(field)
    if self.form.form_fields.where(field.to_sym=>self.send(field)).size>0
      biggest = 0
      self.form.form_fields.where("#{field} like '#{self.send(field)}%'").pluck(field.to_sym).each do |n|
        if n =~ /#{self.send(field)}(\d+)$/
          nn = $1.to_i
          biggest = nn if nn>biggest
        end
      end
      "#{self.send(field)}#{biggest+1}"
    else
      return self.send(field)
    end
  end    
end
