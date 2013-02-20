class QEvent < ActiveRecord::Base

  belongs_to :q_client

  after_create :run_queue

  def run_queue
    Delayed::Job.enqueue QueueJob.new(self.id)
  end    
end
