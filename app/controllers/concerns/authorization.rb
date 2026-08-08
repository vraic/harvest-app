module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
    # Uncomment to enforce Pundit authorization for every controller.
    # Add `skip_after_action :verify_authorized` for public controllers.

    # after_action :verify_authorized
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    helper_method :staff?, :customer?, :manager?, :customer_only?, :any_customer_role?, :visible_account_ids,
                  :storefront_accessible_account?, :current_account_storefront_accessible?,
                  :show_staff_shop_navigation?, :staff_shop_navigation_label
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
      if Current.user&.admin? && Current.account.blank?
        Account.unscoped.pluck(:id)
      elsif storefront_store_operator?
        (Account.unscoped.where(is_b2c: true).pluck(:id) + supplier_authorized_store_ids).uniq
      else
        Account.unscoped.where(is_b2c: true).pluck(:id)
      end
    end
  end

  def storefront_accessible_account?(account)
    return false if account.blank?

    if Current.user&.admin? && Current.account.blank?
      true
    elsif storefront_store_operator?
      account.is_b2c? || supplier_authorized_store?(account)
    else
      account.is_b2c?
    end
  end

  def current_account_storefront_accessible?
    storefront_accessible_account?(Current.account)
  end

  def show_staff_shop_navigation?
    staff_shop_navigation_label.present?
  end

  def staff_shop_navigation_label
    return unless Current.account

    return "Customer View" if Current.account.is_b2c?
    return "Supplier View" if storefront_store_operator? && supplier_authorized_store_ids.any?

    nil
  end

  private

  # You can also customize the messages using the policy and action to generate the I18n key
  # https://github.com/varvet/pundit#creating-custom-error-messages
  def storefront_store_operator?
    return false unless Current.user
    return true if Current.user.admin? && Current.account.present?

    AccountUser.unscoped.where(user: Current.user, user_role: [ :store_manager, :store_staff ]).exists?
  end

  def storefront_store_operator_account_ids
    return [] unless Current.user
    return [ Current.account.id ] if Current.user.admin? && Current.account.present?

    AccountUser.unscoped.where(user: Current.user, user_role: [ :store_manager, :store_staff ]).distinct.pluck(:account_id)
  end

  def supplier_authorized_store?(account)
    return false unless account&.is_b2b?

    supplier_authorized_store_ids.include?(account.id)
  end

  def supplier_authorized_store_ids
    @supplier_authorized_store_ids ||= begin
      operator_account_ids = storefront_store_operator_account_ids
      if operator_account_ids.blank?
        []
      else
        Supplier.unscoped
                .where(supplier_account_id: operator_account_ids, account_id: Account.unscoped.where(is_b2b: true).select(:id))
                .distinct
                .pluck(:account_id)
      end
    end
  end

  def user_not_authorized
    redirect_back_or_to root_path, alert: t("unauthorized")
  end
end
