class View < ActiveRecord::Base
  belongs_to :layout
  belongs_to :page_template

  def  template_type_enum
    ['erb', 'haml', 'builder']
  end


end
