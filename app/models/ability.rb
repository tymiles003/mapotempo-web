
class Ability
  include CanCan::Ability
  def initialize(user)
    if user
      if user.admin?
        can :access, :rails_admin       # only allow admin users to access Rails Admin
        can :dashboard                  # allow access to dashboard
        can :manage, :all
      else
        can [:edit, :update], User, :id => user.id
        can [:index, :edit, :update], Vehicle, :user_id => user.id
        can :manage, Destination, :id => user.store_id
        can :manage, Destination, :user_id => user.id
        can :manage, Planning, :user_id => user.id
        can :manage, Route, :planning => {:user_id => user.id}
      end
    end
  end
end

