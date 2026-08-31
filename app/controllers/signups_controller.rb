class SignupsController < ApplicationController
  allow_unauthenticated_access
  layout "sessions"

  def new
    @user = User.new(email_address: params[:email_address].to_s.strip.downcase.presence)
    @account = Account.find_by(id: params[:account_id]) if params[:account_id]
  end

  def create
    @user = User.new(user_params)
    @account = Account.find_by(id: params[:account_id]) if params[:account_id]

    unless valid_signup_invite_code?
      @user.errors.add(:base, "A valid invite code is required to sign up.")
      render :new, status: :unprocessable_content
      return
    end

    if @user.save
      if @account
        Customer.create!(account: @account, user: @user, name: @user.name, email_address: @user.email_address)
        session[:managed_account_id] = @account.id
      end

      start_new_session_for(@user)
      @user.password = @user.password_confirmation = nil
      redirect_to security_setup_path, notice: "Account created"
    else
      render :new, status: :unprocessable_content
    end
  end

  private
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
