class PageLinkJob < Struct.new(:system_id)

  def perform
    last_crawl = (Time.zone.parse(Preference.get(system_id, "last_crawl")) rescue nil)
    this_crawl = Time.now
    Preference.set(system_id, "last_crawl", this_crawl)
      Rails.logger.debug "Last crawl #{last_crawl} This Crawl #{this_crawl}"
      pages = Page
      pages = pages.sys(system_id) unless system_id == 0
      pages = pages.where(["needs_crawl > ?", last_crawl]) if last_crawl
      pages = pages.where(["needs_crawl <= ?", this_crawl])
      pages.where("needs_crawl is not null").find_each do |p|
        Rails.logger.debug "Crawling page #{p.id}"
        p.crawl
      end
  end

  def error(job, e)
    Preference.set(system_id, "last_crawl", nil)
    notes = []
    notes << "Exception Message: #{e.message}"
    notes << "Stack Trace: #{e.backtrace.join("\n")}"
    reference =  Digest::MD5.hexdigest(Time.now.to_s)[0..8]
    Event.store("PageLinkJob error", nil, 0, notes.join("\n"), reference) 
    Activity.add(system_id, "Page Link refresh Failed #{reference}", 0, "System", '')
    Rails.logger.error "PageLinkJob error: #{reference} #{e.message}"
  end

  def success(job)
    Activity.add(system_id, "Page Links refreshed", 0, "System", '')
  end

end

