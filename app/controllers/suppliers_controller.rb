class SuppliersController < ApplicationController
  before_action :require_account!
  before_action :set_supplier, only: %i[ show edit update update_retention_hold destroy anonymise inventory ]
  before_action :set_selectable_supplier_accounts, only: %i[ new create ]

  def index
    suppliers = policy_scope(Supplier)

    if params[:query].present?
      # Try to find by exact name or email first since they are encrypted and search_cop (LIKE) won't work
      matching_suppliers = suppliers.where(name: params[:query].strip).or(suppliers.where(email_address: params[:query].strip))

      if matching_suppliers.any?
        suppliers = matching_suppliers
      else
        suppliers = suppliers.search(params[:query])
      end
    end

    @pagy, @suppliers = pagy(suppliers)
  end

  def show
    authorize @supplier
  end

  def new
    @supplier = Supplier.new
    @supplier_entry_mode = "platform_store"
    authorize @supplier
  end

  def edit
    authorize @supplier
  end

  def create
    @supplier = Supplier.new(supplier_params)
    @supplier_entry_mode = supplier_entry_mode
    apply_supplier_entry_mode!
    authorize @supplier

    respond_to do |format|
      if @supplier.errors.none? && @supplier.save
        format.html { redirect_to @supplier, notice: "Supplier was successfully created." }
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @supplier.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @supplier
    respond_to do |format|
      if @supplier.update(supplier_params)
        format.html { redirect_to @supplier, notice: "Supplier was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @supplier }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @supplier.errors, status: :unprocessable_content }
      end
    end
  end

  def update_retention_hold
    authorize @supplier, :update?

    if @supplier.update(retention_hold_params)
      DataRetention::EventRecorder.record!(
        account: @supplier.account,
        record: @supplier,
        event_type: @supplier.retention_hold_active? ? "manual_hold_enabled" : "manual_hold_disabled",
        action_name: "manual_hold",
        details: retention_hold_event_details(@supplier),
        actor: Current.user
      )

      notice = @supplier.retention_hold_active? ? "Supplier marked to be retained." : "Supplier retention hold removed."
      redirect_to supplier_path(@supplier), notice:, status: :see_other
    else
      redirect_to supplier_path(@supplier), alert: @supplier.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    authorize @supplier
    @supplier.destroy!
    respond_to do |format|
      format.html { redirect_to suppliers_path, notice: "Supplier was archived.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def anonymise
    authorize @supplier, :destroy?
    @supplier.anonymise!
    @supplier.destroy! unless @supplier.deleted?
    respond_to do |format|
      format.html { redirect_to suppliers_path, notice: "Supplier was anonymised.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def inventory
    authorize @supplier
    @inventory_items = @supplier.inventory_items
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    attributes = [ :name, :email_address, :phone, :subscribed_to_newsletter, :supplier_account_id ]
    attributes += [ :account_id ] if Current.user.admin?
    params.require(:supplier).permit(attributes)
  end

  def retention_hold_params
    params.require(:supplier).permit(:retention_hold, :retention_hold_until, :retention_hold_reason)
  end

  def retention_hold_event_details(supplier)
    details = []
    details << "Hold enabled" if supplier.retention_hold_active?
    details << "Hold until #{supplier.retention_hold_until}" if supplier.retention_hold_until.present?
    details << "Reason: #{supplier.retention_hold_reason}" if supplier.retention_hold_reason.present?
    (details.presence || [ "Hold removed" ]).join(". ")
  end

  def supplier_entry_mode
    mode = params.dig(:supplier, :entry_mode)
    mode.in?([ "platform_store", "manual_entry" ]) ? mode : "platform_store"
  end

  def apply_supplier_entry_mode!
    if @supplier_entry_mode == "manual_entry"
      @supplier.supplier_account = nil
      return
    end

    supplier_store = @selectable_supplier_accounts.find_by(id: params.dig(:supplier, :supplier_account_id))
    if supplier_store.blank?
      @supplier.supplier_account = nil
      @supplier.errors.add(:supplier_account, "must be selected")
      return
    end

    @supplier.supplier_account = supplier_store
    @supplier.name = supplier_store.name if @supplier.name.blank?
    @supplier.email_address = supplier_store.owner&.email_address if @supplier.email_address.blank?
  end

  def set_selectable_supplier_accounts
    excluded_account_id = Current.account&.id
    @selectable_supplier_accounts = Account.unscoped.includes(:owner).where.not(id: excluded_account_id).order(:name)
  end
end
