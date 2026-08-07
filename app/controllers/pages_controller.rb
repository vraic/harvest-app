class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  def home
    if authenticated?
      if customer_only?
        redirect_to shop_path
      else
        redirect_to dashboard_path
      end
    end
  end

  def dashboard
    redirect_to new_session_path unless authenticated?

    if Current.user && !Current.user.admin? && Current.user.accounts.empty?
      process_referral
    end

    if Current.account
      if staff? || manager?
        @open_orders_count = Order.ordered.count
        @pending_supplier_requests_count = SupplierRequest.where(receiver_account: Current.account, status: :pending).count
        @incomplete_tasks_count = Task.incomplete.count
        @low_stock_items_count = InventoryItem.low_stock.count.size
        @suppliers = Supplier.all
      end

      @customer = Customer.find_by(user_id: Current.user.id)
      @loyalty_card = @customer&.loyalty_card if @customer
      @loyalty_program = Current.account.loyalty_program
    end

    @customer_orders = Order.unscoped.includes(:account).joins(:customer).where(customers: { user_id: Current.user.id }).order(created_at: :desc).limit(5)
    @top_products = InventoryItem.unscoped.includes(:account)
                                 .joins(order_items: { order: :customer })
                                 .where(customers: { user_id: Current.user.id })
                                 .group(:id)
                                 .select("inventory_items.*, COUNT(order_items.id) as order_count")
                                 .order("order_count DESC")
                                 .limit(5)
  end

  private

  def process_referral
    referral_code = cookies.signed[:referral]
    return if referral_code.blank?

    code = Refer::ReferralCode.find_by(code: referral_code)
    return unless code && code.referrer_type == "Account"

    account = code.referrer
    return unless account

    # Associate as customer
    Customer.unscoped.where(account: account, user: Current.user).first_or_create!(
      name: Current.user.name,
      email_address: Current.user.email_address
    )

    # Also redirect to refresh or set notice
    flash[:notice] = "Welcome! You've been joined to #{account.name}."
    cookies.delete(:referral)
  end
end
