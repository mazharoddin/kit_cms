class AdminController < GnricController
  before_filter :can_moderate

  layout "cms-boxed"
end
