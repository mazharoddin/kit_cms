class PageTemplateTerm < ActiveRecord::Base
  belongs_to :page_template
  belongs_to :form_field_type
  has_many :terms
  belongs_to :created_by, :class_name=>"User", :foreign_key=>"created_by"

  validates :name, :presence=>true

  def code_name
    self.name.urlise
  end
end
