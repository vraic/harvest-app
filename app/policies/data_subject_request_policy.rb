class DataSubjectRequestPolicy < ApplicationPolicy
  def index?
    user.admin? || staff?
  end

  def show?
    return true if user.admin?

    requester_in_current_account?
  end

  def create?
    return false unless user
    return true if user.admin?

    manager? && Current.account.present?
  end

  def update?
    return true if user.admin?

    manager? && requester_in_current_account?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        tenant = ActsAsTenant.current_tenant || Current.account
        return scope.none unless tenant

        scope.where(account_id: tenant.id, requester_id: user.id)
      end
    end
  end

  private

  def requester_in_current_account?
    tenant = ActsAsTenant.current_tenant || Current.account
    return false unless tenant

    record.requester_id == user.id && record.account_id == tenant.id
  end
end
