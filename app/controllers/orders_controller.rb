class OrdersController < ApplicationController
  before_action :require_account!, except: %i[ index show ]
  before_action :set_order, only: %i[ show edit update destroy awaiting_collection complete ]

  # GET /orders or /orders.json
  def index
    @query = params[:query]
    scope = policy_scope(Order).includes(:account, :order_items, order_items: { inventory_item: { image_attachment: :blob } }).order(created_at: :desc)

    if params[:filter] == "today"
      scope = scope.where(created_at: Time.current.all_day)
    end

    if @query.present?
      clean_query = @query.delete("#").strip

      # Since name and email are encrypted, search_cop (LIKE) won't work. We handle exact match here.
      # We search in the current scope's tenant if possible, or unscoped if admin
      customer_ids = if Current.account
        Current.account.customers.where(name: clean_query).or(Current.account.customers.where(email_address: clean_query)).pluck(:id)
      else
        Customer.unscoped.where(name: clean_query).or(Customer.unscoped.where(email_address: clean_query)).pluck(:id)
      end

      begin
        decoded_id = Order.decode_prefix_id(clean_query)
      rescue StandardError
        decoded_id = nil
      end

      if decoded_id
        scope = scope.where(id: decoded_id)
      elsif clean_query.match?(/^\d{3}[A-Z]{3}$/)
        scope = scope.where(number: clean_query)
      elsif customer_ids.any?
        scope = scope.where(customer_id: customer_ids)
      else
        if @query.match?(/^\d+(\.\d{2})?$/)
          cents = (@query.to_f * 100).to_i
          scope = scope.search("#{@query} OR total_amount_cents: #{cents}")
        else
          scope = scope.search(@query)
        end
      end
    end

    @pagy, @orders = pagy(scope)
  end

  def awaiting_collection
    authorize @order, :update?
    @order.awaiting_collection!
    redirect_to @order, notice: "Order is now awaiting collection."
  end

  def complete
    authorize @order, :update?
    @order.complete!
    redirect_to @order, notice: "Order has been completed."
  end

  # GET /orders/1 or /orders/1.json
  def show
    authorize @order
  end

  # GET /orders/new
  def new
    @order = Order.new

    if customer? && !current_cart.empty?
      current_cart.items.each do |item|
        @order.order_items.build(
          inventory_item: item.product,
          quantity: item.quantity,
          price: item.product.price
        )
      end
    else
      @order.order_items.build
    end

    authorize @order
    prepare_loyalty_data
  end

  # GET /orders/1/edit
  def edit
    authorize @order
    prepare_loyalty_data
  end

  # POST /orders or /orders.json
  def create
    @order = Order.new(order_params)
    @order.account = Current.account
    @order.user = Current.user if staff?

    if Current.user&.admin? && session[:managed_account_id].present?
      @order.user = Current.account.owner
    end

    if customer?
      @order.customer = Customer.find_by(user: Current.user, account: Current.account)

      # B2B Fallback: if no personal record, use the one linked to any of the user's accounts
      if @order.customer.nil?
        user_account_ids = AccountUser.unscoped.where(user: Current.user).pluck(:account_id)
        @order.customer = Customer.find_by(account: Current.account, customer_account_id: user_account_ids)
      end
    end

    authorize @order

    respond_to do |format|
      if persist_order_with_payment
        session[:cart] = nil if customer?
        format.html { redirect_to @order, notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        @order.order_items.build if @order.order_items.empty?
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    authorize @order
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: "Order was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    authorize @order
    @order.destroy!

    respond_to do |format|
      format.html { redirect_to orders_path, notice: "Order was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.unscoped.find(params[:id])
    end

    def prepare_loyalty_data
      @loyalty_program = Current.account.loyalty_program
      if @loyalty_program&.active?
        @customers_data = Current.account.customers.includes(:loyalty_card).each_with_object({}) do |customer, hash|
          hash[customer.id] = { loyalty_card: customer.loyalty_card }
        end
      end
    end

    def persist_order_with_payment
      return false unless @order.valid?

      payment = build_payment
      return false if payment.nil?

      Order.transaction do
        @order.save!
        payment.order = @order
        payment.save!
      end

      true
    rescue ActiveRecord::RecordInvalid
      payment&.errors&.full_messages&.each { |message| @order.errors.add(:base, message) }
      false
    end

    def build_payment
      selected_method = selected_payment_method

      unless Payment.payment_methods.key?(selected_method)
        @order.errors.add(:base, "Payment method is invalid")
        return nil
      end

      if selected_method == "gocardless" && !@order.customer&.gocardless_configured?
        @order.errors.add(:base, "GoCardless setup is required before using this payment option")
        return nil
      end

      @order.build_payment(
        account: @order.account,
        customer: @order.customer,
        payment_method: selected_method,
        status: :pending,
        amount_cents: @order.total_amount_cents,
        currency: @order.total_amount.currency.iso_code,
        provider_reference: provider_reference_for(selected_method)
      )
    end

    def provider_reference_for(selected_method)
      return @order.customer.gocardless_mandate_id if selected_method == "gocardless"

      nil
    end

    # Only allow a list of trusted parameters through.
    def order_params
      permitted_attributes = [ :customer_id, :location_id, :notes, :status, :loyalty_points_redeemed,
                               order_items_attributes: [ :id, :inventory_item_id, :location_id, :quantity, :price, :_destroy ] ]

      params.require(:order).permit(permitted_attributes)
    end

    def selected_payment_method
      params.dig(:order, :payment_method).presence || "cash_on_collection"
    end
end
