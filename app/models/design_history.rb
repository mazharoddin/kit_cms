class DesignHistory < ActiveRecord::Base
  
  belongs_to :user

  def self.record(object)
    dh = DesignHistory.new
    dh.system_id = object.system_id
    dh.model_id = object.id
    dh.model = object.class.name
    dh.body = object.body
    dh.header = object.header if object.has_attribute?(:header) 
    dh.footer = object.footer if object.has_attribute?(:footer) 
    dh.user_id = object.user_id
    dh.updated_at = Time.now
    dh.save
  end

  def source_object
    eval(self.model).find(self.model_id)
  end
end
