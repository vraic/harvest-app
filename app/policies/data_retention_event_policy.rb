class DataRetentionEventPolicy < ApplicationPolicy
  def index?
    user.admin? || staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(account_id: user.account_users.pluck(:account_id))
      end
    end
  end
end