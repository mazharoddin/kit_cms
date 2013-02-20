class QueueJob < Struct.new(:event_id)

  def perform

    event = QEvent.find(event_id)
    return if event.processed_at

    QSubscription.sys(event.system_id).where(:q_client_id=>event.q_client_id).where(:topic=>event.topic).includes(:q_user).find_each do |sub|
    
      Rails.logger.debug "Sending: #{sub.q_user.twitter_handle}"
    end

    event.processed_at = Time.now
    event.save
  end

  def error(job, e)
    notes = []
    notes << "Exception Message: #{e.message}"
    notes << "Stack Trace: #{e.backtrace.join("\n")}"
    reference =  Digest::MD5.hexdigest(Time.now.to_s)[0..8]
    Event.store("QueueJob error", nil, 0, notes.join("\n"), reference) 
    Rails.logger.error "QueueJob error: #{reference} #{e.message}"
  end

  def success(job)
  end

end


