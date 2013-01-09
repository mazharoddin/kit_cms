class System < ActiveRecord::Base

  def get_system_id
    if self.respond_to?(:system_id)
      (self.system_id==nil || self.system_id == 0) ? self.id : self.system_id
    else
      self.id
    end
  end


end
