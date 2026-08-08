class ManagedAccountsController < ApplicationController
  def update
    account_id = params[:account_id]

    if Current.user.admin?
      if account_id.present?
        account = Account.find(account_id)
        active_request = SupportRequest.unscoped.where(account: account).active.first

        if active_request.present?
          session[:managed_account_id] = account.id
          flash[:notice] = "Now managing #{account.name}"
        else
          session.delete(:managed_account_id)
          flash[:alert] = "Access denied. No active support authorization for this account."
        end
      else
        session.delete(:managed_account_id)
        flash[:notice] = "Switched to Global view"
      end
    elsif account_id.present?
      account = Account.find(account_id)

      # Check direct access
      has_access = AccountUser.unscoped.exists?(user: Current.user, account_id: account.id)

      # Check B2b access through any of the user's accounts
      if !has_access
        user_account_ids = AccountUser.unscoped.where(user_id: Current.user.id).pluck(:account_id)
        if Customer.unscoped.where(account_id: account.id, customer_account_id: user_account_ids).exists?
          # Ensure they have an AccountUser in the target account so set_tenant works
          ActsAsTenant.without_tenant do
            AccountUser.unscoped.where(user_id: Current.user.id, account_id: account.id).first_or_create!(user_role: :customer)
          end
          Current.user.reload
          has_access = true
        end
      end

      if has_access
        session[:managed_account_id] = account.id
        flash[:notice] = "Switched to #{account.name}"
      else
        flash[:alert] = "You do not have access to that account."
      end
    else
      flash[:alert] = "Please select an account."
    end

    redirect_to params[:return_to] || dashboard_path, status: :see_other
  end

  def destroy
    session.delete(:managed_account_id)
    flash[:notice] = "Stopped managing account"
    redirect_to dashboard_path, status: :see_other
  end
end
