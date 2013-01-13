class Preference < ActiveRecord::Base    

  def Preference.get_key(sid, name, user_id = nil)
    "#{sid} : #{name} : #{user_id ? user_id : 'nil'}"
  end

  def Preference.get_cached!(sid, name, value, user_id = nil)
    Rails.cache.fetch(get_key(sid,name,user_id), :expires_in => 10.minutes) do 
     Preference.get!(sid,name, value, user_id)
    end
  end

  def Preference.get_cached(sid,name, user_id = nil)
    Preference.getCached(sid,name)
  end

  def Preference.getCached(sid,name, user_id = nil) #get from cache, then DB if not present in cache
    Rails.cache.fetch(get_key(sid,name,user_id), :expires_in => 10.minutes) do 
     Preference.get(sid, name, user_id)
    end
  end
  
  def Preference.increase(sid,name)
    p = Preference.find_by_name_and_system_id(name, sid, :lock=>true)
    
    p.value = p.value.to_i + 1
    p.save!
    p.value.to_i
  end
  
  def Preference.get(sid,name, user_id = nil) # get from DB
    p = Preference.sys(sid).where(:name => name).where(:user_id=>user_id).first

    return p!=nil ? p.value : nil
  end 

  def Preference.delete(sid, name, user_id=nil)
    Preference.flush(sid, name, user_id)
    pref = Preference.sys(sid).where(:name=>name).where(:user_id=>user_id).first
    pref.destroy
  end

  def Preference.flush(sid,name, user_id) 
   Rails.cache.delete(get_key(sid,name, user_id))
  end

  def Preference.get!(sid,name, value, user_id = nil) # get, but return value if not found
    pref_s = Preference.get(sid,name, user_id)
    if (pref_s==nil)
      pref = Preference.new
      pref.system_id=sid
      pref.name = name
      pref.value = value
      pref.user_id = user_id
      pref.save
      return value
    else
      return pref_s
    end
  end  
  
  def Preference.set(sid,name, value, user_id = nil)
    pref = Preference.where(:name=>name)
    pref = pref.sys(sid)
    pref = pref.where(:user_id=>user_id) if user_id
    pref = pref.first

    if pref==nil
      Preference.get!(sid,name, value, user_id)
    else
      pref.value = value
      pref.save
    end
    Preference.flush(sid,name, user_id)
  end
 
  def Preference.licensed?(sid, name)
    licensed = Rails.cache.fetch("licenses_#{sid}_#{name}", :expires_in=>10.minutes) do 
      Preference.get_cached(sid, "feature_#{name}")=="true" || Preference.get_cached(sid, "feature_*")=="true"
    end

    licensed==true ? true : false
  end

end
