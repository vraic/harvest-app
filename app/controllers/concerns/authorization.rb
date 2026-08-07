module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
    # Uncomment to enforce Pundit authorization for every controller.
    # Add `skip_after_action :verify_authorized` for public controllers.

    # after_action :verify_authorized
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    helper_method :staff?, :customer?, :manager?, :customer_only?, :any_customer_role?, :visible_account_ids
  end

  def pundit_user
    Current.user
  end

  def staff?
    Current.user&.admin? || Current.user&.account_users&.exists?(account: Current.account, user_role: [ :store_manager, :store_staff ])
  end

  def manager?
    return false unless Current.account
    Current.user&.admin? || Current.user&.account_users&.exists?(account: Current.account, user_role: :store_manager)
  end

  def customer?
    Current.user&.account_users&.exists?(account: Current.account, user_role: :customer)
  end

  def customer_only?
    return false unless Current.user
    return false if Current.user.admin?
    return false if Current.user.account_users.none?
    !Current.user.account_users.exists?(user_role: [ :store_manager, :store_staff ])
  end

  def any_customer_role?
    Current.user&.account_users&.exists?(user_role: :customer)
  end

  def visible_account_ids
    @visible_account_ids ||= begin
      if Current.user&.admin?
        Account.unscoped.pluck(:id)
      elsif customer_only?
        Account.unscoped.where(is_b2c: true).pluck(:id)
      else
        Account.unscoped.where("is_b2c = ? OR is_b2b = ?", true, true).pluck(:id)
      end
    end
  end

  private

  # You can also customize the messages using the policy and action to generate the I18n key
  # https://github.com/varvet/pundit#creating-custom-error-messages
  def user_not_authorized
    redirect_back_or_to root_path, alert: t("unauthorized")
  end
end
