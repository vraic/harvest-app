class CustomersController < ApplicationController
  before_action :require_account!
  before_action :set_customer, only: %i[ show edit update destroy anonymise really_destroy ]

  # GET /customers or /customers.json
  def index
    customers = policy_scope(Customer)
    @showing_archived = showing_archived?
    customers = @showing_archived ? customers.only_deleted : customers
    customers = customers.where("customers.created_at >= ?", 7.days.ago) if params[:filter] == "recent" && !@showing_archived

    if params[:query].present?
      # Try to find by exact name or email first since they are encrypted and search_cop (LIKE) won't work
      matching_customers = customers.where(name: params[:query].strip).or(customers.where(email_address: params[:query].strip))

      if matching_customers.any?
        customers = matching_customers
      else
        customers = customers.search(params[:query])
      end
    end

    @pagy, @customers = pagy(customers)
  end

  # GET /customers/1 or /customers/1.json
  def show
    authorize @customer
  end

  # GET /customers/new
  def new
    @customer = Customer.new
    authorize @customer
  end

  # GET /customers/1/edit
  def edit
    authorize @customer
  end

  # POST /customers or /customers.json
  def create
    @customer = Customer.new(customer_params)
    authorize @customer

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: "Customer was successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @customer.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /customers/1 or /customers/1.json
  def update
    authorize @customer
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: "Customer was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @customer.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /customers/1 or /customers/1.json
  def destroy
    authorize @customer
    @customer.destroy!

    respond_to do |format|
      format.html { redirect_to customers_index_path_for_redirect, notice: "Customer was archived.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def anonymise
    authorize @customer, :destroy?
    @customer.anonymise!
    @customer.destroy! unless @customer.deleted?

    respond_to do |format|
      format.html { redirect_to customers_index_path_for_redirect, notice: "Customer was anonymised.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def really_destroy
    authorize @customer
    @customer.destroy_fully!

    respond_to do |format|
      format.html { redirect_to customers_index_path_for_redirect, notice: "Customer was permanently deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = customer_lookup_scope.find(params[:id])
    end

    def customer_lookup_scope
      if %w[show anonymise really_destroy].include?(action_name)
        Customer.with_deleted
      else
        Customer
      end
    end

    def showing_archived?
      params[:view] == "archived"
    end

    def customers_index_path_for_redirect
      showing_archived? ? customers_path(view: "archived") : customers_path
    end

    # Only allow a list of trusted parameters through.
    def customer_params
      attributes = [ :name, :email_address, :phone, :subscribed_to_newsletter ]
      attributes += [ :account_id ] if Current.user.admin?
      params.require(:customer).permit(attributes)
    end
end
