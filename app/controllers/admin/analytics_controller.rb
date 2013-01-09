class Admin::AnalyticsController < AdminController
  before_filter :licensed

  def index
    unless Preference.get(_sid,'google_analytics_id')
      render "setup"
    end
  end

  def setup
    if request.post?
      google_analytics_id = params[:google_analytics_id].strip
      unless google_analytics_id =~ /^UA-\d\d\d\d\d\d?\d?\d?\d?-\d$/
        flash[:notice] = "The Analytics Account ID doesn't look valid"
        return
      end
      Preference.set(_sid,'google_analytics_id', google_analytics_id)

      [ :google_api_browser_key, :google_api_client_id, :google_analytics_profile_id ].each do |key|
        if params[key].not_blank?
          value = params[key].strip

          Preference.set(_sid, key.to_s, value)
        end
      end
      redirect_to "/db/analytics"
    end
  end
end
