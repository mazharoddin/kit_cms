class Admin::DjController < AdminController

  def index

    if request.post? && params[:delete]
      DelayedJob.delete_all("id = #{params[:delete]} and queue = '#{_sid}'")
      redirect_to "/admin/dj", :notice=>"Job deleted"
    end

    if request.post? && params[:process]
      do_process
      redirect_to "/admin/dj"
    end

    @delayed_jobs = DelayedJob.where(:queue=>_sid).order("created_at desc").page(params[:page]).per(100).all
   
    @running = false
    if File.exist?("tmp/pids/delayed_job.pid")
      begin
        @pid = File.read("tmp/pids/delayed_job.pid").strip
        Process.getpgid( @pid.to_i )
        @running = true
      rescue Errno::ESRCH
      end
    end
  end

  def do_process
    if params[:process]
      `bundle exec script/delayed_job #{params[:process]}`
      flash[:notice] = "Process #{params[:process]}"
    end
  end

end

