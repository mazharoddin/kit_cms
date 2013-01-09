class FormSubmissionField < ActiveRecord::Base
  belongs_to :form_submission
  belongs_to :form_field

  def field_type
    self.form_field.form_field_type.field_type
  end

  def index_value
    self.value ? self.value : '[none]'
  end
end
