class SubmissionCheck < ActiveRecord::Base

  def self.exists?(check)
    SubmissionCheck.where(:check_code=>check).first != nil
  end

  def self.record(check)
    SubmissionCheck.create(:check_code=>check)
  end

end
