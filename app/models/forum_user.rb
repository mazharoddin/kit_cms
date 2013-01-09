class ForumUser < ActiveRecord::Base
  belongs_to :user
  
  def self.load(user)
    if user==nil
      r = ForumUser.load_default
    else
      r = user.forum_user
      unless r
        default = ForumUser.load_default
        r = ForumUser.create(:user_id=>user.id, :threads_per_page=>default.threads_per_page,
                                :posts_per_page=>default.posts_per_page,
                                :thread_order=>default.thread_order,
                                :post_order=>default.post_order)
      end
    end

    return r
  end

  def default_user?
    self.user_id == 0
  end  

  def self.load_default
    r = ForumUser.where("user_id = 0").first
    if r==nil
      r = ForumUser.create(:user_id=>0, :threads_per_page=>10, :posts_per_page=>10, :thread_order=>"asc", :post_order=>"desc")
    end

    return r
  end
end
