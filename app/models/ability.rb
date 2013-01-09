class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.superadmin?
      can :use, :all
      can :moderate, :all
      can :manage, :all
      can :dashboard, :super
      can :dashboard, :all
      can :access, :sys_admin
      can :moderate, :calendar
      can :use, :design
    end

    if user.designer?
      can :use, :design
    end

    if user.moderator?
      can :moderate, :all
      can :moderate, :calendar
    end

    if user.editor?
      can :use, [BlocksController, PagesController, CategoryController, Admin::UserController, Admin::DashboardController, Admin::PreferenceController, ImagesController, LinksController]
      can :moderate, :all
      can :moderate, :calendar
    end

  end
end
