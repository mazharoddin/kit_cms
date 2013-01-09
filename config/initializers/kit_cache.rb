module KitCache

  @@kit_cache = {}

  class CacheEntry 
    attr_accessor :object
    attr_accessor :access_count
  end

  def using_kit_caching
    return @@kit_cache[self.name]
  end

  def use_kit_caching(max_size = 100, name_field = 'name')
    @@kit_cache[self.name] = {:max_size=>max_size, :name_field=>name_field, :cache=>{}}

    after_save { self.class.cache_clear }
  end


  def cache_key(sys_id, id)
    "__#{self.name}_#{sys_id}_#{id}"
  end

  def cache_get(sys_id, id) 
    return nil unless cache = @@kit_cache[self.name]
    cache_entry = self.cache_entry(cache, sys_id, id)
    return cache_entry if cache_entry

    object = self.find_sys_id(sys_id, id)
    return nil unless object

    self.cache_put(cache, object, sys_id, id) 
    return object
  end

  def cache_entry(cache, sys_id, id)
    return nil unless cache 

    entry = cache[:cache][self.cache_key(sys_id, id)]
    return nil unless entry
    entry.access_count += 1
    return entry.object   
  end

  def cache_put(cache, object, sys_id, id)
    ce = CacheEntry.new
    ce.object = object
    ce.access_count = 0
    if cache[:cache].size > cache[:max_size] # removes 10% of entries if size exceeded, least used first out
      entries_to_remove = cache[:cache].sort_by { |key, entry| entry.access_count }[0..(cache[:max_size]/10).to_i]
      entries_to_remove.each { |key, entry| cache[:cache].delete(key) }
    end
    cache[:cache][self.cache_key(sys_id, id)] = ce
  end

  def cache_flush(sys_id, id)
    @@kit_cache[self.name][self.cache_key(sys_id, id)] = nil
  end

  def cache_clear
    @@kit_cache[self.name][:cache] = {}
  end
end

ActiveRecord::Base.send(:extend, KitCache)
