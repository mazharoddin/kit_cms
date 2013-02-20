require 'bcrypt'
require 'digest/md5'

class QClient < ActiveRecord::Base
  include BCrypt
  
  belongs_to :system
  has_many :q_subscriptions, :dependent => :destroy
  has_many :q_users, :dependent => :destroy

  def auth_secret
    @auth_secret ||= Password.new(encrypted_auth_secret)
  end

  def auth_secret=(new_secret)
    @auth_secret = Password.create(new_secret)
    self.encrypted_auth_secret = @auth_secret
  end

  def generate_auth_secret
    gen = Digest::MD5.hexdigest(Time.now.to_s + rand(10000000).to_s)
    puts "Generate auth secret: #{gen}"
    self.auth_secret = gen
    self.save
  end
end
