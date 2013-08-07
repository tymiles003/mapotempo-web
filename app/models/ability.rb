
class Ability
  include CanCan::Ability
  def initialize(user)
    if user
      if user.admin?
        can :access, :rails_admin       # only allow admin users to access Rails Admin
        can :dashboard                  # allow access to dashboard
        can :manage, :all
      else
        can :manage, User, :id => user.id
        can :manage, Vehicle, :user_id => user.id
        can :manage, Destination, :user_id => user.id
        can :manage, Planning, :user_id => user.id
      end
    end
  end
end

