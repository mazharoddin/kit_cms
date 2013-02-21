class Newsletter < ActiveRecord::Base
  has_many :users
  has_many :newsletter_sends

  class NewsletterJob
    attr_accessor :send_id
    attr_accessor :test_mode

    def perform
      ns = NewsletterSend.find(self.send_id) 
      mail = Mail.new(ns.newsletter.raw_mail)
      mail.subject =~ /^newsletter: (.*)$/i
      subject = $1
      Newsletter.send_email("#{self.test_mode ? '***TEST***' : ''}#{subject}",  mail.content_type, mail.body, ns.id)
    end
  end

  def send_now(sid, user, comment, test = true)

    ns = NewsletterSend.new
    ns.newsletter_id = self.id
    ns.is_test = test
    ns.sent_at = Time.now
    ns.sent_by = user.id
    ns.comment = comment
    ns.save

    recipients = self.recipients(sid, test)
    recipients.each do |recip|
      nn = NewsletterSent.new
      nn.newsletter_sends_id = ns.id
      nn.email = recip.email
      nn.user_id = recip.id
      nn.status = "queued"
      nn.save
    end

    job = NewsletterJob.new
    job.send_id = ns.id
    job.test_mode = test

    Delayed::Job.enqueue job, :queue=>sid

    self.status = test ? "test" : "sent"
    self.save
  end

  def Newsletter.make(raw_mail, mail)
    n = Newsletter.new
    mail.subject =~ /^newsletter: (.*)$/i
    n.name = $1
    n.raw_mail = raw_mail
    n.status = "unsent"
    n.save
    return n
  end

  def Newsletter.munge_id(id)
    id.gsub(/[^a-z0-9]/i, '')
  end

  def recipients(sid, test = true, load_records = true)

    if test 
      users = {}
      uu = []
      roles = Preference.get_cached(sid,"newsletter_test_roles")
      roles.split('|').each do |role|

        Role.sys(self.system_id).where(:name=>role).first.users.each do |u|
          if users[u.email]==nil
            uu << u
            users[u.email] = 1
          end
        end
      end
      r = User.where("id in (#{uu.collect {|u| u.id }.join(',')})")
    else
      r =  User.sys(sid).where("subscribe_newsletter=1")
    end

    return load_records ? r.all : r
  end

  def Newsletter.process_mail(mail,sid)
    if mail.header["X-Failed-Recipients"]
      logger.debug "Found failure message"
      mail.body.to_s =~ /^X-DSC-sent-id: ([0-9]+)\s+/
      sent_id = $1
      limit = Preference.get_cached(sid,"newsletter_address_fail_limit").to_i rescue 5
      logger.debug "Sent ID was #{sent_id}"
      nl = NewsletterSent.find(sent_id) rescue nil
      u = nl.user rescue nil
      if u
        u.email_failures += 1
        if u.email_failures > limit
          u.subscribe_newsletter = false
        end
        u.save
      end

      return true
    else
      return false
    end
  end

  def Newsletter.send_email(sid, subject, content_type, body, send_id, user = nil)
    smtp = Newsletter.connect_smtp(sid)
    sender = Preference.get_cached(sid, "newsletter_sender")
    sender_name = Preference.get_cached(sid, "newsletter_sender_name")

    if send_id
      recipients = NewsletterSent.where(:status=>"queued").where(:newsletter_sends_id=>send_id).includes([:user]).all
    else
      recipients = User.sys(sid).where(:id=>user.id).all
    end

      recipients.each do |recip|
        unless Preference.get_cached(sid, "newsletter_live") == 'true'
          unless recip.email =~ /dsc.net/
            if send_id
              recip.status = "skipped"
              recip.save
            end
            next
          end
        end

        msg = <<END_OF_MESSAGE
From: "#{sender_name}" <#{sender}>
To: #{recip.email}
Subject: #{subject}
Content-Type: #{content_type}
X-DSC-sent-id: #{recip.id}

#{body}
END_OF_MESSAGE

        status = ""
        begin
          smtp.sendmail msg, sender, recip.email
          status = "sent"
        rescue Exception => e
          status = e.to_s
          smtp.finish
          smtp = Newsletter.connect_smtp(sid)
        end

        if send_id
          recip.status = status
          recip.save
        end
    end
  end


  def Newsletter.connect_smtp(sid)
    use_ssl = Preference.get_cached(sid, "newsletter_use_ssl")=="true"
    port = use_ssl ? 465 : 25
    smtp = Net::SMTP.new(Preference.get_cached(sid, "newsletter_pop_server"), port)
    if use_ssl
      context = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      smtp.enable_ssl(context)
    end
    smtp.start("localhost", Preference.get_cached(sid, "newsletter_pop_email"), Preference.get_cached(sid, "newsletter_pop_password"), :login) 
  end
end
