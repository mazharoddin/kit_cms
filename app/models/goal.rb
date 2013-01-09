class Goal < ActiveRecord::Base
  belongs_to :user

  after_save { Goal.refresh_cache(self.system_id) }
  after_destroy { Goal.refresh_cache(self.system_id) }

  has_many :experiments
  has_many :goals_users

  def Goal.record_request(sid, url, cookies, user, started, session)
    begin
    Goal.ensure_cache(sid)

    if started.is_a?(String)
      started = Time.parse(started)
    end
    @@cache[sid].each do |index, goal|
      scored = false
      if goal.goal_type=='URL'
        if goal.match_type=='Exact Match'
         scored = true if url == goal.match_value
        elsif goal.match_type=='Starts'
         scored = true if url.starts_with?(goal.match_value)
        end 
      elsif goal.goal_type=='Session Time'
        next if session["hitgoal_#{goal.id}"] # already hit
        scored = true if started + goal.session_minutes.to_i.minutes < Time.now
        session["hitgoal_#{goal.id}"] = true
      end

      if scored # i.e. goal has been met
        recorded = false # we record if they're in an experiment, but also if they're not.  if they are the goal hit will be recorded in the experiment checking loop, so don't do it again.  if not, do do it
        goal.experiments.each do |experiment|
          option = cookies["experiment_#{experiment.id}".to_sym].to_i rescue 0
          if option>0
            goal.goals_users << GoalsUser.new(:user=>user, :experiment_option=>option, :kit_session_id=>session[:session_id], :system_id=>sid)
            experiment.update_attributes("goals#{option}".to_sym=>experiment.send("goals#{option}") + 1)
            recorded = true
          end
        end
          
        goal.goals_users << GoalsUser.new(:user=>user, :kit_session_id=>session[:session_id]) unless recorded
      end
    end
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.join('\r\n'))
    end
  end

  @@cache = nil

  def self.clear_cache
    @@cache = {}
  end

  def Goal.refresh_cache(sid)
    Goal.clear_cache

    Goal.all.each do |goal|
      @@cache[sid] ||= {}
      @@cache[sid][goal.id] = goal
    end
  end

  def Goal.goals
    @@cache
  end

  def Goal.load(sid, id)
    @@cache[sid][id]
  end

  def Goal.has_goals?(sid)
    ensure_cache(sid)
    @@cache[sid].size > 0 rescue false
  end

  def Goal.ensure_cache(sid)
    refresh_cache(sid) if @@cache==nil
  end

end
