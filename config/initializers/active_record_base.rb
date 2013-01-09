module ActiveRecord 
  class Base 


    scope :sys, lambda { |sys_id| {:conditions => { :system_id => sys_id } }}

    scope :name_or_id, lambda { |p|
      if p.is_number?
        { :conditions => { :id=> p } }
      else
        { :conditions => { :name => p } }
      end
    }

    scope :sys_id, lambda { |sys_id, id| 
      { :conditions=> [{:system_id=>sys_id}, {:id=>id}]}
    }

    scope :sys_name_or_id, lambda { |sys_id, p|
      if p.is_number?
        { :conditions=> [{:system_id=>sys_id}, {:id=>p}]}
      else
        { :conditions=> [{:system_id=>sys_id}, {:name=>p}]}
      end
    }

    def self.find_sys_id(sid, id, name_field = 'name') 
      if id.is_number?
        where(:id=>id).where(:system_id=>sid).first
      else
        where(name_field=>id).where(:system_id=>sid).first
      end
    end

    def self.find_by_name_or_id(id, name_field = 'name')
      if id.is_number?
        where(:id=>id).first
      else
        where(name_field=>id).first
      end
    end

    def self.merge_conditions(*conditions) 
      segments = []

      conditions.each do |condition| 
        unless condition.blank? 
          sql = sanitize_sql(condition) 
          segments << sql unless sql.blank? 
        end 
      end 
      "(#{segments.join(') AND (')})" unless segments.empty? 
    end 
  end 
end


