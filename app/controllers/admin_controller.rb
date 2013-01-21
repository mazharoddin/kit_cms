class AdminController < KitController
  before_filter :can_moderate

  layout "cms"
end
