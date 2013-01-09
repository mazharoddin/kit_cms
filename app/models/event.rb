class Event < ActiveRecord::Base
  
  belongs_to :user
  
  def self.store(name, request, user_id = nil, notes = nil, reference = nil)
    
    e = Event.new(:name=>name, :url=>request ? request.fullpath : "n/a", :ip_address=>request ? request.remote_ip : "n/a", :user_id=>user_id, :notes=>notes, :reference=>reference)
    e.save
   
    if name != "404 error"
      logger.debug "Sending?"
      Notifications.event(e).deliver rescue nil
    end
        
    return e
  end
end

