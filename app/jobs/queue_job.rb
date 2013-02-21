require 'twitter'

class QueueJob < Struct.new(:event_id)

  def perform

    @event = QEvent.find(event_id)
    return if @event.processed_at

    bodies = {} # keyed on klass, i.e. the database record which shows how to generate the message body

    twitter = Twitter::Client.new(
      :consumer_key => @event.q_client.twitter_consumer_key,
      :consumer_secret => @event.q_client.twitter_consumer_secret,
      :oauth_token => @event.q_client.twitter_oauth_token,
      :oauth_token_secret => @event.q_client.twitter_oauth_token_secret
    )

    QSubscription.sys(@event.system_id).where(:q_client_id=>@event.q_client_id).where(:topic=>@event.topic).includes(:q_user).find_each do |sub|
  
      notification_method = sub.q_user.notification_method
      body = bodies[notification_method]
      unless body
        klass = QKlass.sys(@event.system_id).where(:q_client_id=>@event.q_client_id).where(:name=>@event.klass).first
        if klass
          body = eval(klass.code)
        else
          body = @event.data
        end

        bodies[notification_method] = body
      end
      
      sent = QSent.new(:q_client=>@event.q_client, :q_event=>@event, :q_subscription=>sub, :q_user=>sub.q_user, :body=>body)

      next unless body.not_blank?
      begin
        if notification_method=='twitter'
          if sub.q_user.source==1
            twitter.update(body) # tweet
            sent.destination = "tweet"
          else
            next unless sub.q_user.twitter_handle.not_blank?
            twitter.direct_message_create(sub.q_user.twitter_handle, body) # direct message
            sent.destination = "@#{sub.q_user.twitter_handle}"
          end
        elsif notification_method=='email'
          sent.destination = sub.q_user.email
        end
        sent.status = "OK"
      rescue Exception => e
        sent.status = e.message 
      end
      sent.save

      sub.last_notification = Time.now
      sub.save
    end

    @event.processed_at = Time.now
    @event.save
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


