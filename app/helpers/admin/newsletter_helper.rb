module Admin::NewsletterHelper

  def receiver(r)
    if r.instance_of?(User)
      r
    else
      r.user
    end
  end
end
