module Admin::AnalyticsHelper

  def get(name)
    Preference.getCached(_sid, name)
  end

end
