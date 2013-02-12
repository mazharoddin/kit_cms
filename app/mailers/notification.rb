include ActionView::Helpers::TextHelper

class Notification < ActionMailer::Base
  helper :kit_modules

  def report_post_admin(report,sid)
    @post = report.topic_post

    @email = report.user.email
    @user = report.user.display_name
    @sid = sid
    mail(:from=>isfrom(sid), :to => Preference.getCached(sid, "report_post_notification"), :subject => "Reported Post")
  end

  def new_post(post, to_user)
    @sid = post.system_id
    @post = post
    @to_user = to_user

    mail :subject=>"#{Preference.get_cached(@sid, "site_name")}: New post on thread '#{truncate(post.topic_thread.title, :length=>80, :ommission=>'...')}'", :to=>@to_user.email, :from=>isfrom(@sid)
  end

  def forgotten_password(to_user_id)
    @user = User.find(to_user_id)
    reset_url = Preference.get_cached(@user.system_id, "account_reset_url") || "/users/reset"

    @reset_link =  Preference.get_cached(@user.system_id, "host") + reset_url + "/" + @user.reset_password_token
    mail :subject=>t("account.forgotten_password_subject"),
         :to=>@user.email,
         :from=>isfrom(@user.system_id)
  end

  def welcome_message(to, sid)
    @sid = sid
    mail(:from=>isfrom(sid), :to=>to.email, :subject=>"Thanks for joining")
  end

  def event(event, sid)
    @e = event
    mail :from=>isfrom(sid),:subject=>"Event #{event.id} occurred: #{event.name}",  :to => Preference.getCached(sid, 'notify:event')
  end

  def form_submission(submission_id,sid, recipient)
    @sub = FormSubmission.find(submission_id)
    @sid = sid
    mail :subject=>"#{Preference.getCached(sid,'app_name')} #{@sub.form.title} Submission",
           :to=>recipient, :from=>isfrom(sid)
  end

  def moderation_required(object_type, message,sid)
    type = object_type.urlise
    @message  = message
    @type = object_type
    notify = Preference.get_cached(sid,"notify_#{type}") || Preference.get_cached(sid,"notify")
      mail :subject=>"#{type} Requires Moderation",
            :to=>notify, :from=>isfrom(sid)
  end

  def send_message(user_note, sid)
    @user_note = user_note
    @sid = sid
    mail :from=>isfrom(sid), :to=>user_note.user.email, :subject=>user_note.subject
  end

  private

  def isfrom(sid)
    Preference.getCached(sid,"notifications_from")
  end
end
