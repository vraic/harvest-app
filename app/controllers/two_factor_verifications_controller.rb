class TwoFactorVerificationsController < ApplicationController
  allow_unauthenticated_access
  layout "sessions"

  EMAIL_OTP_EXPIRY = 15.minutes

  before_action :set_user

  def new
    if !@user.otp_enabled?
      if @user.email_otp_token.blank? || @user.email_otp_sent_at.nil? || @user.email_otp_sent_at < EMAIL_OTP_EXPIRY.ago
        @user.generate_email_otp!
      end
    end
  end

  def create
    @user.reload
    if verify_otp
      @user.clear_email_otp!
      start_new_session_for @user
      session.delete(:otp_user_id)

      target_url = if session[:security_setup_user_id] == @user.id && !@user.security_choice_made?
        session.delete(:security_setup_user_id)
        security_setup_url
      else
        after_authentication_url(@user)
      end

      redirect_to target_url, notice: "Signed in successfully.", status: :see_other
    else
      flash.now[:alert] = "Invalid verification code."
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find_by(id: session[:otp_user_id])
    redirect_to new_session_path if @user.nil?
  end

  def verify_otp
    if @user.otp_enabled?
      result = @user.validate_otp(params[:otp_code])
      logger.info "TOTP verification for User #{@user.id}: #{result ? 'SUCCESS' : 'FAILED'}"
      result
    else
      result = @user.validate_email_otp(params[:otp_code])
      logger.info "Email OTP verification for User #{@user.id}: #{result ? 'SUCCESS' : 'FAILED'}"
      result
    end
  end
end
