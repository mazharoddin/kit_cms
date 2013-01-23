class Experiment < ActiveRecord::Base
  # attr_accessible :title, :body
  #
  belongs_to :user
  belongs_to :goal

  validates :end_date, :presence=>true

  after_save { Experiment.flush_cache }
  after_destroy { Experiment.flush_cache }

  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^page_(\d+)$/
      page($1)
    else
      super
    end
  end

  def page(n)
    url = self.send("url#{n}")

    Page.sys(self.system_id).where(:full_path=>"/#{url}").first
  end

  @@cache = {}

  def Experiment.flush_cache
    @@cache = {}
  end

  def invoke(option)
    if option!=nil
      alt = option.to_i
    else
      participate = ((100 - percentage_visitors) * 10) < (1 + rand(1000))
      alt = participate ? rand(2) + 1 : 0
    end
    self.update_attributes("impressions#{alt}" => self.send("impressions#{alt}") + 1) if alt != 0 && option==nil
    return [self.send("url#{alt==0 ? 1 : alt}"), alt]
  end

  def Experiment.alternative(sid, url)
    key = Experiment.cache_key(sid, url)
    return @@cache[key] if @@cache.include?(key)

    # simple method to stop it getting too big
    Exerpiemtn.flush_cache if @@cache.size > 10000
  
    e = Experiment.sys(sid).where(:url1=>url).where("experiments.end_date>now()").where("experiments.enabled=1").first

    @@cache[key] = e || false
  end

  def Experiment.cache_key(sid, url)
    return "#{sid}_#{url}"
  end

end
