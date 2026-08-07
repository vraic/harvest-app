class ApplicationController < ActionController::Base
  set_referral_cookie
  include Authentication
  include Authorization
  include Pagy::Method

  set_current_tenant_through_filter
  before_action :set_tenant

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def find_current_auditor
    Current.user
  end

  def current_user
    Current.user
  end

  def current_cart
    @current_cart ||= Cart.new(session)
  end
  helper_method :current_cart

  def require_account!
    return if Current.user&.admin? # Admins can have nil account (Global view)

    if Current.account.nil?
      redirect_to dashboard_path, alert: "Please select a store to continue."
    end
  end

  private

    def set_tenant
      return unless authenticated?

      account_id = session[:managed_account_id]
      user = Current.user

      if user.admin?
        account = Account.find_by(id: account_id) if account_id && account_id != "none"

        if account
          active_request = SupportRequest.unscoped.where(account: account).active.first
          if active_request.nil?
            logger.warn "SECURITY: Admin #{user.id} attempted to access account #{account.id} without active support request"
            account = nil
            session.delete(:managed_account_id)
            flash[:alert] = "Access denied. No active support authorization for this account."
          end
        end

        set_current_tenant(account)
        ActsAsTenant.current_tenant = account # Explicitly set for models
      else
        # For non-admins, they must belong to the account
        if account_id && account_id != "none" && AccountUser.unscoped.where(user_id: user.id, account_id: account_id).exists?
          account = Account.find(account_id)
          set_current_tenant(account)
        elsif account_id == "none"
          set_current_tenant(nil)
        else
          # Fallback to single account if no account selected or membership lost
          user_account_ids = AccountUser.unscoped.where(user_id: user.id).pluck(:account_id).uniq
          if user_account_ids.count == 1
            account = Account.find(user_account_ids.first)
            set_current_tenant(account)
          else
            set_current_tenant(nil)
          end
        end
      end

      Current.account = ActsAsTenant.current_tenant
    end
end
