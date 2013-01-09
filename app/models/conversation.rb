class Conversation < ActiveRecord::Base
  has_many :conversation_users
  has_many :users, :through=>:conversation_users

  has_many :messages

  attr_accessor :messages_waiting

  def self.flush
    # end user's part in a conversation if not heard from them in the last X minutes
    ConversationUser.connection.execute("delete from conversation_users where user_id not in (select id from users where last_heard_from > date_sub(now(), interval 1 minute))")

    # end the conversation if only one user remains
    Conversation.connection.execute("delete from conversations where id not in (select conversation_id from (select conversation_id, count(*) as cnt from conversation_users cu group by conversation_id) cu2 where cu2.cnt > 1 )")

    # clean out users from conversations that don't exist any longer
    Conversation.connection.execute("delete from conversation_users where conversation_id not in (select id from conversations)")
  end

  def link
    "/convo/" + self.id.to_s
  end
end
