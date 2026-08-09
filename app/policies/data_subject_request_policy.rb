class DataSubjectRequestPolicy < ApplicationPolicy
  def index?
    user.admin? || staff?
  end

  def show?
    user.admin? || account_member? || record.requester_id == user.id
  end

  def create?
    return false unless user
    return true if user.admin?

    Current.account.present? || record.account_id.present?
  end

  def update?
    return true if user.admin?

    manager? && account_member?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        account_ids = user.account_users.pluck(:account_id)
        scope.where(account_id: account_ids).or(scope.where(requester_id: user.id))
      end
    end
  end

  private

  def account_member?
    user.account_users.exists?(account_id: record.account_id)
  end
end
