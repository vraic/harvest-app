class DataSubjectRequestsController < ApplicationController
  before_action :require_account!
  before_action :set_data_subject_request, only: %i[ show update ]
  before_action :set_form_options, only: %i[ new show ]

  def index
    requests = policy_scope(DataSubjectRequest)
      .includes(:account, :requester, :subject_user, :acted_by)
      .order(due_on: :asc, created_at: :desc)

    if params[:status].present? && DataSubjectRequest.statuses.key?(params[:status])
      requests = requests.where(status: params[:status])
    end

    @pagy, @data_subject_requests = pagy(requests)
  end

  def show
    authorize @data_subject_request
  end

  def new
    @data_subject_request = DataSubjectRequest.new(account: Current.account, subject_user: Current.user)
    authorize @data_subject_request
  end

  def create
    permitted_params = data_subject_request_params
    evidence_files = extract_evidence_files(permitted_params)

    @data_subject_request = DataSubjectRequest.new(permitted_params)
    @data_subject_request.requester = Current.user
    @data_subject_request.account = Current.account unless Current.user.admin?
    @data_subject_request.account ||= Current.account
    authorize @data_subject_request

    if @data_subject_request.save
      @data_subject_request.evidence_files.attach(evidence_files) if evidence_files.any?
      redirect_to data_subject_request_path(@data_subject_request), notice: "Data rights request submitted."
    else
      set_form_options
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @data_subject_request
    permitted_params = data_subject_request_params
    evidence_files = extract_evidence_files(permitted_params)

    if @data_subject_request.update(permitted_params)
      @data_subject_request.evidence_files.attach(evidence_files) if evidence_files.any?

      if params[:complete_request] == "1"
        @data_subject_request.mark_completed!(actor: Current.user)
      elsif @data_subject_request.completed? && @data_subject_request.offboarding_action_required?
        @data_subject_request.apply_offboarding_action!(actor: Current.user)
      end

      redirect_to data_subject_request_path(@data_subject_request), notice: "Data rights request updated."
    else
      set_form_options
      render :show, status: :unprocessable_content
    end
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    @data_subject_request.errors.add(:base, e.message)
    set_form_options
    render :show, status: :unprocessable_content
  end

  private

  def set_data_subject_request
    @data_subject_request = DataSubjectRequest.find(params[:id])
  end

  def set_form_options
    account = @data_subject_request&.account || Current.account
    @available_subject_users = if account
      AccountUser.active
        .where(account_id: account.id)
        .includes(:user)
        .map(&:user)
        .compact
        .uniq
        .sort_by { |user| user.name.to_s }
    else
      []
    end
  end

  def data_subject_request_params
    permitted = [
      :request_type,
      :status,
      :subject_user_id,
      :request_summary,
      :legal_basis,
      :due_on,
      :decision_summary,
      :offboarding_action,
      :completion_evidence,
      { evidence_files: [] }
    ]

    permitted << :account_id if Current.user.admin?
    params.require(:data_subject_request).permit(permitted)
  end

  def extract_evidence_files(permitted_params)
    Array(permitted_params.delete(:evidence_files)).reject(&:blank?)
  end
end
