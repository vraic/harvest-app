class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create test_login ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." } unless Rails.env.test?

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

  def create
    email_address = params[:email_address].to_s.strip.downcase
    user = User.find_by(email_address: email_address)

    if user&.authenticate(params[:password])
      session[:otp_user_id] = user.id
      session.delete(:security_setup_user_id)

      if user.otp_required_for_login? || user.prefers_email_login?
        user.generate_email_otp! unless user.otp_enabled?
        user.password = user.password_confirmation = nil
        redirect_to new_two_factor_verification_path, status: :see_other
      else
        start_new_session_for user
        redirect_to after_authentication_url(user), notice: "Signed in successfully.", status: :see_other
      end
    elsif params[:password].present?
      redirect_to new_session_path, alert: "Try another email address or password.", status: :see_other
    else
      user = find_or_create_email_login_user(email_address)
      session[:otp_user_id] = user.id
      session[:security_setup_user_id] = user.id unless user.security_choice_made?
      user.generate_email_otp!
      user.password = user.password_confirmation = nil
      redirect_to new_two_factor_verification_path, notice: "We emailed you a one-time code.", status: :see_other
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def find_or_create_email_login_user(email_address)
    User.find_or_create_by!(email_address: email_address) do |user|
      user.name = email_address.split("@").first.to_s.humanize
      user.password = user.password_confirmation = SecureRandom.alphanumeric(32)
      user.prefers_email_login = true
    end
  end
end
