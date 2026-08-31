class SupplierRequestsController < ApplicationController
  before_action :require_account!, except: %i[ new ]
  before_action :set_supplier_request, only: %i[ update destroy ]

  def index
    @pagy, @supplier_requests = pagy(policy_scope(SupplierRequest))
  end

  def new
    @receiver_account = Account.find_by(id: params[:receiver_account_id])

    # Reload user to ensure we have the latest account associations (important after new store creation)
    Current.user.reload
    @managed_accounts = ActsAsTenant.without_tenant { Current.user.account_users.store_manager.includes(:account).map(&:account) }

    # If sender_account_id is provided, try to use it
    if params[:sender_account_id].present?
      sender = @managed_accounts.find { |a| a.id == params[:sender_account_id].to_i }
      if sender
        session[:managed_account_id] = sender.id
        # Need to set tenant for the current request context if we just changed it
        ActsAsTenant.current_tenant = sender
        Current.account = sender
      end
    end

    # If the current account is not one we manage as store_manager, we act as if no account is selected
    effective_current_account = @managed_accounts.include?(Current.account) ? Current.account : nil

    if @managed_accounts.any? && effective_current_account.nil?
      # If they have accounts but none (that they manage) is selected, show selection
      @supplier_request = SupplierRequest.new(receiver_account: @receiver_account)
    elsif effective_current_account
      @supplier_request = SupplierRequest.new(receiver_account: @receiver_account, sender_account: effective_current_account)
      authorize @supplier_request
    else
      @supplier_request = SupplierRequest.new(receiver_account: @receiver_account)
      # No managed accounts, skip authorization here as we'll show the "Account Required" view
    end
  end

  def create
    @supplier_request = SupplierRequest.new(supplier_request_params)
    @supplier_request.sender_account = ActsAsTenant.current_tenant
    authorize @supplier_request

    if @supplier_request.save
      redirect_to supplier_requests_path, notice: "Request sent"
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @supplier_request
    if @supplier_request.update(status: params[:status])
      redirect_to supplier_requests_path, notice: "Request #{params[:status]}"
    else
      redirect_to supplier_requests_path, alert: "Update failed"
    end
  end

  def destroy
    authorize @supplier_request
    @supplier_request.destroy!
    redirect_to supplier_requests_path, notice: "Request removed", status: :see_other
  end

  private

  def set_supplier_request
    @supplier_request = SupplierRequest.find(params[:id])
  end

  def supplier_request_params
    params.require(:supplier_request).permit(:receiver_account_id)
  end
end
