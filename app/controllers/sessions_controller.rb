class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new identify password create test_login ]
  rate_limit to: 10, within: 3.minutes, only: %i[ identify create ], with: -> { redirect_to new_session_path, alert: "Try again later." } unless Rails.env.test?

  layout "sessions"

  def new
  end

  def test_login
    if Rails.env.test?
      user = User.find(params[:user_id])
      start_new_session_for user
      redirect_to dashboard_path, notice: "Logged in as #{user.email_address}"
    else
      head :forbidden
    end
  end

  def identify
    email_address = normalized_email(params[:email_address])
    if email_address.blank?
      redirect_to new_session_path, alert: "Enter your email address.", status: :see_other
      return
    end

    user = User.find_by(email_address: email_address)

    if user.nil?
      redirect_to new_signup_path(email_address: email_address), alert: "No account found for that email. Please sign up first.", status: :see_other
    elsif user.prefers_email_login?
      send_magic_link(user)
      redirect_to new_two_factor_verification_path, notice: "We emailed you a one-time code.", status: :see_other
    else
      redirect_to password_session_path(email_address: email_address), status: :see_other
    end
  end

  def password
    email_address = normalized_email(params[:email_address])
    @user = User.find_by(email_address: email_address)

    if @user.nil? || @user.prefers_email_login?
      redirect_to new_session_path
      return
    end

    @email_address = email_address
  end

  def create
    email_address = normalized_email(params[:email_address])
    if email_address.blank?
      redirect_to new_session_path, alert: "Enter your email address.", status: :see_other
      return
    end

    user = User.find_by(email_address: email_address)

    if user&.authenticate(params[:password])
      if user.force_password_reset?
        session.delete(:otp_user_id)
        session.delete(:security_setup_user_id)
        redirect_to edit_password_path(user.password_reset_token), alert: "Please reset your password to continue.", status: :see_other
      elsif user.otp_required_for_login? || user.prefers_email_login?
        session[:otp_user_id] = user.id
        session.delete(:security_setup_user_id)
        user.generate_email_otp! unless user.otp_enabled?
        user.password = user.password_confirmation = nil
        redirect_to new_two_factor_verification_path, status: :see_other
      else
        start_new_session_for user
        redirect_to after_authentication_url(user), notice: "Signed in successfully.", status: :see_other
      end
    elsif params[:password].present?
      redirect_to password_session_path(email_address: email_address), alert: "Try another email address or password.", status: :see_other
    elsif user
      send_magic_link(user)
      redirect_to new_two_factor_verification_path, notice: "We emailed you a one-time code.", status: :see_other
    else
      redirect_to new_signup_path(email_address: email_address), alert: "No account found for that email. Please sign up first.", status: :see_other
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def normalized_email(value)
      value.to_s.strip.downcase
    end

    def send_magic_link(user)
      session[:otp_user_id] = user.id
      session[:security_setup_user_id] = user.id unless user.security_choice_made?
      user.generate_email_otp!
      user.password = user.password_confirmation = nil
    end
end
