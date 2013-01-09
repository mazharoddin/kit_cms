class TopicPostVote < ActiveRecord::Base

  belongs_to :user
  belongs_to :topic_post

  after_create :create_scores
  after_update :update_scores

  def create_scores
    self.topic_post.created_by_user.forum_points += self.score
    self.topic_post.created_by_user.forum_votes += 1
    self.topic_post.created_by_user.save
    self.topic_post.score += self.score
    self.topic_post.save
  end

  def update_scores
    return unless self.score_changed?

    self.topic_post.created_by_user.forum_points -= self.score_was
    self.topic_post.created_by_user.forum_points += self.score
    self.topic_post.created_by_user.save

    self.topic_post.score -= self.score_was
    self.topic_post.score += self.score
    self.topic_post.save
  end

end
