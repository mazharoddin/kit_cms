class Term < ActiveRecord::Base
  belongs_to :page_template_term
  belongs_to :page

  before_save :update_value_urlised

  def update_value_urlised
    self.value_urlised = self.value.urlise
  end

end
