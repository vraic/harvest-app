class StoreMembershipsController < ApplicationController
  def create
    account = Account.find(params[:account_id])

    # Check if already a member
    already_member = if Current.user.admin? && Current.account
      account.customers.exists?(customer_account: Current.account)
    else
      AccountUser.unscoped.where(user_id: Current.user.id, account_id: account.id).exists?
    end

    if already_member
      message = "Already a member"
      redirect_to dashboard_path, alert: message
      return
    end

    # Create Customer record - this will also create AccountUser via callback
    ActsAsTenant.with_tenant(account) do
      Customer.create!(
        user: Current.user,
        customer_account: (Current.account if Current.user.admin?),
        name: (Current.account&.name if Current.user.admin?) || Current.user.name,
        email_address: Current.user.email_address
      )
    end

    # Switch context if not already managing an account, or if not an admin (keep existing behavior for regular users)
    unless Current.user.admin? && session[:managed_account_id].present?
      session[:managed_account_id] = account.id
    end

    Current.user.reload
    redirect_to dashboard_path, notice: "Joined #{account.name}"
  end
end
