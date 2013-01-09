class IpCountry < ActiveRecord::Base

  @@cache = {}

  def self.country_from_ip(ip)
    if cached = @@cache[ip]
      return cached
    end
  
    if @@cache.size > 1000
      i = 100
      @@cache.each do |k,v| 
        @@cache.delete(k)
        i += 1
        break if i > 100
      end
    end

    lookup = IpCountry.select("name, risk, inet_aton('#{ip}') as ipd, ip_from, country_code").where("ip_to >= inet_aton('#{ip}')").first
    if lookup
      if lookup.ipd <= lookup.ip_from
        lookup = IpCountry.new(:risk=>50, :name=>"Unknown") 
      else
        @@cache[ip] = lookup
      end
    end

    return lookup
  end
end
