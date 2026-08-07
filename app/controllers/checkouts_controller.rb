class CheckoutsController < ApplicationController
  skip_before_action :set_tenant
  before_action :require_authentication

  def show
    @cart = current_cart
    if @cart.empty?
      redirect_to shop_path, alert: "Your cart is empty."
      return
    end

    @grouped_items = @cart.grouped_items
    @orders_data = @grouped_items.map do |account, items|
      {
        account: account,
        items: items,
        total_price: items.sum(&:total_price),
        collection_points: Location.unscoped.where(account: account, collection_point: true)
      }
    end
  end

  def create
    @cart = current_cart
    checkout_params = params[:checkout] || {}
    payment_method = params[:payment_method] || "cash_on_collection"

    orders = []
    errors = []

    ActiveRecord::Base.transaction do
      @cart.grouped_items.each do |account, items|
        ActsAsTenant.with_tenant(account) do
          order_params = checkout_params[account.id.to_s] || {}

          customer = Customer.find_or_create_by!(user: Current.user) do |c|
            c.name = Current.user.name
            c.email_address = Current.user.email_address
          end

          order = Order.new(
            account: account,
            customer: customer,
            location_id: order_params[:location_id],
            notes: order_params[:notes],
            status: :ordered
          )

          items.each do |item|
            order.order_items.build(
              inventory_item: item.product,
              quantity: item.quantity,
              price: item.product.price,
              location_id: order_params[:location_id]
            )
          end

          # Run validation to trigger calculate_total and ensure amounts are set
          order.valid?

          # Build payment
          if payment_method == "gocardless" && !customer&.gocardless_configured?
            errors << "#{account.name}: GoCardless setup is required"
            next
          end

          order.build_payment(
            account: account,
            customer: customer,
            payment_method: payment_method,
            status: :pending,
            amount_cents: order.total_amount_cents,
            currency: "GBP",
            provider_reference: (customer.gocardless_mandate_id if payment_method == "gocardless")
          )

          if order.save
            orders << order
          else
            errors << "#{account.name}: #{order.errors.full_messages.to_sentence}"
          end
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.empty? && orders.any?
      session[:cart] = nil
      redirect_to orders_path, notice: "Orders successfully created."
    else
      flash.now[:alert] = "Unable to complete checkout: #{errors.to_sentence}"
      @grouped_items = @cart.grouped_items
      @orders_data = @grouped_items.map do |account, items|
        {
          account: account,
          items: items,
          total_price: items.sum(&:total_price),
          collection_points: Location.unscoped.where(account: account, collection_point: true)
        }
      end
      render :show, status: :unprocessable_content
    end
  end
end
