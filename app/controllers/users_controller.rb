class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  layout :resolve_layout
  before_action :set_user, only: %i[ show edit update destroy anonymise really_destroy ]

  # GET /users or /users.json
  def index
    @pagy, @users = pagy(User.all)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new(email_address: params[:email_address].to_s.strip.downcase.presence)
    @account = Account.find_by(id: params[:account_id]) if params[:account_id]
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    is_signup = !authenticated?

    if is_signup && !valid_signup_invite_code?
      @user.errors.add(:base, "A valid invite code is required to sign up.")

      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end

      return
    end

    respond_to do |format|
      if @user.save
        # Handle account association if provided during signup
        if params[:account_id].present? && is_signup
          account = Account.find_by(id: params[:account_id])
          if account
            # Create Customer record - this will also create AccountUser via callback
            Customer.create!(account: account, user: @user, name: @user.name, email_address: @user.email_address)
            session[:managed_account_id] = account.id
          end
        end

        start_new_session_for(@user) if is_signup
        @user.password = @user.password_confirmation = nil
        format.html { redirect_to (is_signup ? security_setup_path : @user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        @user.password = @user.password_confirmation = nil
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    if @user.admin?
      redirect_to users_path, alert: "Cannot delete admin users."
      return
    end

    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was archived.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def anonymise
    if @user.admin?
      redirect_to users_path, alert: "Cannot anonymise admin users."
      return
    end

    @user.anonymise!
    @user.destroy! unless @user.deleted?

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was anonymised.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def really_destroy
    unless Current.user.admin?
      redirect_to users_path, alert: "Only global admins can permanently delete users."
      return
    end

    if @user.admin?
      redirect_to users_path, alert: "Cannot delete admin users."
      return
    end

    @user.destroy_fully!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was permanently deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    def resolve_layout
      authenticated? ? "application" : "sessions"
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:email_address, :password, :name)
    end

    def valid_signup_invite_code?
      expected_code = ENV["SIGNUP_INVITE_CODE"].to_s.strip
      provided_code = params[:signup_invite_code].to_s.strip

      return false if expected_code.blank? || provided_code.blank?
      return false unless expected_code.bytesize == provided_code.bytesize

      ActiveSupport::SecurityUtils.secure_compare(provided_code, expected_code)
    end
end
