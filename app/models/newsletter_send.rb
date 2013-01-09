class NewsletterSend < ActiveRecord::Base
  belongs_to :newsletter
  belongs_to :newsletter_sents
end
