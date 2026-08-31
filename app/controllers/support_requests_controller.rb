class SupportRequestsController < ApplicationController
  before_action :set_support_request, only: %i[ show update destroy ]

  def index
    @pagy, @support_requests = pagy(policy_scope(SupportRequest).includes(:account, :requester).order(created_at: :desc))
  end

  def show
    authorize @support_request
  end

  def new
    @support_request = SupportRequest.new
    @support_request.account_id = params[:account_id] if params[:account_id]
    authorize @support_request
  end

  def create
    @support_request = SupportRequest.new(support_request_params)
    @support_request.account ||= Current.account
    @support_request.requester = Current.user
    apply_business_override(@support_request) if Current.user.admin?
    authorize @support_request

    if @support_request.save
      redirect_to support_requests_path, notice: "Request created"
    else
      @accounts = Account.all if Current.user.admin?
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @support_request

    if params[:support_request] && params[:support_request][:status] == "accepted"
      @support_request.grant_authorization!
      notice = "Request accepted"
    elsif params[:support_request] && params[:support_request][:status] == "extension_requested"
      duration = params[:duration].to_i
      unit = params[:unit] # hours, days, weeks
      # Validate and update message with extension details maybe?
      # For now just set status.
      @support_request.update!(status: :extension_requested)
      notice = "Extension requested"
    else
      @support_request.update!(support_request_params)
      notice = "Request updated"
    end

    redirect_to support_requests_path, notice: notice
  end

  def extend
    @support_request = SupportRequest.find(params[:id])
    authorize @support_request, :update?

    duration = params[:duration].to_i
    unit = params[:unit] || "hours"

    new_expiry = case unit
    when "hours" then @support_request.expires_at + duration.hours
    when "days" then @support_request.expires_at + duration.days
    when "weeks" then @support_request.expires_at + duration.weeks
    else @support_request.expires_at + 72.hours
    end

    @support_request.update!(expires_at: new_expiry, status: :accepted)
    redirect_to support_requests_path, notice: "Authorization extended"
  end

  def destroy
    authorize @support_request
    @support_request.destroy!
    redirect_to support_requests_path, notice: "Request deleted", status: :see_other
  end

  private

  def set_support_request
    @support_request = SupportRequest.find(params[:id])
  end

  def support_request_params
    permitted = [ :message, :status ]
    permitted << :account_id if Current.user.admin?
    params.require(:support_request).permit(permitted)
  end

  def apply_business_override(support_request)
    support_request.business_override = params.dig(:support_request, :business_override)
    support_request.business_override_confirmation = params.dig(:support_request, :business_override_confirmation)

    return unless support_request.business_override?
    return unless support_request.business_override_confirmation?

    support_request.apply_business_override!(confirmed_by: Current.user)
  end
end
