class NewsletterSent < ActiveRecord::Base
  belongs_to :user
  belongs_to :newsletter
  has_many :newsletter_sends
end
