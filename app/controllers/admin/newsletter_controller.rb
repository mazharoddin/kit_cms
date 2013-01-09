require 'net/pop'
require 'net/smtp'

class Admin::NewsletterController < AdminController
  layout "cms-boxed" 
  before_filter { licensed("newsletters") }

  def email
    @newsletter = Newsletter.where(:id=>params[:id]).sys(_sid).first

    mail = Mail.new(@newsletter.raw_mail)

    Newsletter.send_email(@newsletter.name, mail.content_type, mail.body, nil, current_user)
    flash[:notice] = "Email sent"
    redirect_to "/admin/newsletters/#{@newsletter.id}"
  end

  def history
    @newsletter = Newsletter.where(:id=>params[:id]).sys(_sid).first

    if params[:recips]
      @send = NewsletterSend.where(:id=>params[:recips]).sys(_sid)
      @recipients = NewsletterSent.includes(:user).order("created_at desc").where(:newsletter_sends_id=>@send.id).page(params[:page]).per(100)
    elsif params[:check]
      @send = nil
      @recipients = @newsletter.recipients(_sid, params[:test], false).page(params[:page]).per(100)
    else
      @recipients = nil
    end
  end

  def send_now
    @newsletter = Newsletter.where(:id=>params[:id]).sys(_sid).first

    test = params[:test]!=nil

    @sent = false
    if @newsletter.status=='sent'  && !params[:confirm]
      @already_sent = true
      return
    end

    if @newsletter.status=='unsent'  && !params[:confirm] && !test
      @not_sent_test = true
      return
    end

    @newsletter.send_now(_sid, current_user, '', test)
    @sent = true
  end

  def index
    @newsletters = Newsletter.order("newsletters.created_at desc").sys(_sid)

    @newsletters = @newsletters.where("newsletters.name like '%#{params[:search]}%'")
    @newsletters = @newsletters.page(params[:page]).per(50)
    
  end

  def preview
    @newsletter = Newsletter.where(:id=>params[:id]).sys(_sid)
    
  end

  def fetch
    if Preference.get_cached(_sid, 'newsletter_use_ssl') == 'true'
      Net::POP.enable_ssl
    end

    pop = Net::POP3.new Preference.get_cached(_sid, 'newsletter_pop_server')
    pop.start Preference.get_cached(_sid, 'newsletter_pop_email'), Preference.get_cached(_sid, 'newsletter_pop_password')
    @mails = []

    pop.mails.each { |m| 
      mm = Mail.new(m.pop)
      if mm.subject =~ /^newsletter\:\s?\S+/i
        Newsletter.make(m.pop,mm)
        @mails << mm
        delete = true
      else
        delete = Newsletter.process_mail(_sid, mm)
      end
      m.delete if delete
    }    
    pop.finish
    flash[:notice] = "Checked messages for account #{Preference.get_cached(_sid, 'newsletter_pop_email')}"

  end
end
