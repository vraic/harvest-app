class AccountsController < ApplicationController
  before_action :set_account, only: %i[ show edit update destroy join leave audits ]

  # GET /accounts or /accounts.json
  def index
    @pagy, @accounts = pagy(policy_scope(Account).includes(:account_users))
  end

  def join
    authorize @account
    ActsAsTenant.without_tenant do
      AccountUser.unscoped.where(account: @account, user: Current.user).first_or_create!(user_role: :store_manager)
    end
  rescue ActiveRecord::RecordNotUnique
    # Already exists, ignore
  ensure
    session[:managed_account_id] = @account.id
    redirect_to dashboard_path, notice: "Joined #{@account.name} as a support team member."
  end

  def leave
    authorize @account
    # Only remove AccountUser if it was a support session (not the owner)
    if Current.user.admin? && @account.owner_id != Current.user.id
      AccountUser.unscoped.where(account: @account, user: Current.user).delete_all
    end

    # Use "none" to indicate explicitly no account selected, to prevent ApplicationController fallback
    session[:managed_account_id] = "none"

    notice = if Current.user.admin?
      "Left support session for #{@account.name}."
    else
      "Stopped managing #{@account.name}."
    end

    redirect_to root_path, notice: notice
  end

  def audits
    authorize @account, :show?
    @pagy, @audits = pagy(@account.associated_audits.reorder(created_at: :desc))
  end

  # GET /accounts/1 or /accounts/1.json
  def show
    authorize @account
    @account_users = @account.account_users.includes(:user).order("users.name")
  end

  # GET /accounts/new
  def new
    @account = Account.new(owner_id: Current.user.id)
    authorize @account
    @tab = params[:tab] || "general"
  end

  # GET /accounts/1/edit
  def edit
    authorize @account
    @account.build_loyalty_program unless @account.loyalty_program
    @tab = params[:tab] || "general"
  end

  # POST /accounts or /accounts.json
  def create
    @account = Account.new(account_params)
    @account.owner_id ||= Current.user&.id
    authorize @account

    respond_to do |format|
      if @account.save
        session[:managed_account_id] = @account.id

        if Current.user&.admin?
          format.html { redirect_to params[:return_to] || @account, notice: "Account was successfully created." }
        else
          format.html { redirect_to params[:return_to] || dashboard_path, notice: "Account was successfully created." }
        end
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @account.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /accounts/1 or /accounts/1.json
  def update
    authorize @account
    @tab = params[:tab] || "general"
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: "Account was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @account }
      else
        @account.build_loyalty_program unless @account.loyalty_program
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @account.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /accounts/1 or /accounts/1.json
  def destroy
    authorize @account
    @account.destroy!

    respond_to do |format|
      format.html { redirect_to accounts_path, notice: "Account was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def account_params
      params.require(:account).permit(:name, :address, :owner_id, :header_image, :is_b2c, :is_b2b, :is_internal,
        :gocardless_access_token, :gocardless_mode,
        loyalty_program_attributes: [ :id, :points_to_currency_ratio, :currency_to_points_ratio, :active ])
    end
end
