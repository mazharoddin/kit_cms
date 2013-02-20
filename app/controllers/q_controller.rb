class QController < ApiController

  before_filter :authenticate, :except=>[:token]

  # send system_id and password to get a token which can be use for token authentication (if client auth method is token) or encrypting requests (if client auth method is digest)
  # params: auth_id, auth_secret
  # returns: token
  def token
    client = QClient.sys(_sid).where(:auth_id=>params[:auth_id]).first

    if client && client.auth_secret == params[:auth_secret]
      render :json=>{:auth_id=>client.auth_id, :token=>client.token}
    else
      head :forbidden
    end
  end

  # associate a user ID with a notification method/address
  # params: user (the external ID by which the user is known)
  #         method (the notification method)
  #         address (the address at which they can be notified)
  def register
    quser = @client.q_users.sys(_sid).where(:q_external_id=>params[:user]).first

    unless quser
      quser = QUser.new
      quser.system_id = _sid
      quser.q_client_id = @client.id
      quser.q_external_id = params[:user]
    end

    quser.notification_method = params[:method]
    if params[:method]=='twitter'
      quser.twitter_handle  = params[:address]
    elsif params[:method]=='email'
      quser.email = params[:address]
    end

    quser.save
    unless quser.q_external_id
      quser.q_external_id = quser.id
      quser.save
    end
    render :json=>{:id=>quser.q_external_id}
  end

  # subscribe to a topic (i.e. receive a notification when that topic happens)
  # params: user (the external ID by which the user is known)
  #         topic (the topic to which is being subscribed)
  def subscribe
    quser = @client.q_users.sys(_sid).where(:q_external_id=>params[:user]).first

    unless quser
     head :bad_request
     return
    end
    
    qs = QSubscription.sys(_sid).where(:q_client_id=>@client.id).where(:q_user_id=>quser.id).where(:topic=>params[:topic]).first
    unless qs
      qs = QSubscription.new
      qs.system_id = _sid
      qs.q_client = @client
      qs.q_user = quser
      qs.topic = params[:topic]
      qs.save
    end

    render :json=>{:subscription=>qs.id}
  end

  def event
    event = QEvent.create(:system_id=>_sid, :q_client_id=>@client.id, :topic=>params[:topic])

    render :json=>{:event=>event.id} 
  end

  private
  
  def authenticate
    @client = QClient.sys(_sid).where(:auth_id=>params[:auth_id]).first

    auth = false

    if @client.auth_method=='token'
      auth = authenticate_token
    elsif @client.auth_method=='digest'
      auth = authenticate_digest
    end

    if auth
      return true
    else
      head :forbidden
      return false
    end
  end

  # encrypt, using the token, the digest_secret, the user ID (or '0'), the topic (or '0')
  def authenticate_digest
    aes = FastAES.new(@client.token)
    data = aes.decrypt(params[:digest]).split('-')
#    logger.debug "*** #{data[0]} #{data[1]} #{data[2]}"
    return false unless data[0] == @client.digest_secret
    return false unless data[1] == params[:user] unless data[1]=='0'
    return false unless data[2] == params[:topic] unless data[2]=='0'
    return true 
  end

  def authenticate_token
      if @client.token == params[:token]
        return true
      else
        return false
      end
  end    
  
end

