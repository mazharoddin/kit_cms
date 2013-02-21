require 'bcrypt'
require 'digest/md5'

class QClient < ActiveRecord::Base
  include BCrypt

  attr_accessible :name, :token, :auth_method, :auth_id, :encrypted_auth_secret, :auth_secret, :twitter_consumer_key, :twitter_consumer_secret, :twitter_oauth_token, :twitter_oauth_token_secret
  belongs_to :system
  has_many :q_subscriptions, :dependent => :destroy
  has_many :q_users, :dependent => :destroy
  has_many :q_events, :dependent => :destroy
  has_many :q_klasses, :dependent => :destroy
  has_many :q_sents, :dependent => :destroy

  def auth_secret
    @auth_secret ||= Password.new(encrypted_auth_secret)
  end

  def auth_secret=(new_secret)
    @auth_secret = Password.create(new_secret)
    self.encrypted_auth_secret = @auth_secret
  end

  def generate_auth_secret
    gen = QClient.generate_random
    puts "Generate auth secret: #{gen}"
    self.auth_secret = gen
    self.save
  end

  def QClient.generate_random
    Digest::MD5.hexdigest(Time.now.to_s + rand(10000000).to_s)
  end
end
