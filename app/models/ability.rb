
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
        can [:edit, :update], Customer, :id => user.customer.id
        can [:stop_job_matrix, :stop_job_optimizer, :stop_job_geocoding], Customer
        can [:index, :edit, :update], Vehicle, :customer_id => user.customer.id
        can :manage, Tag, :customer_id => user.customer.id
        can :manage, Destination, :id => user.customer.store_id
        can :manage, Destination, :customer_id => user.customer.id
        can :manage, Zoning, :customer_id => user.customer.id
        if not user.customer.end_subscription or user.customer.end_subscription > Time.now
          can :manage, Planning, :customer_id => user.customer.id
        end
        can :manage, Route, :planning => {:customer_id => user.customer.id}
      end
    end
  end
end

