class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  layout "sessions"

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      if send_password_reset_instructions(user)
        redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
      else
        redirect_to new_password_path, alert: "Couldn't send password reset instructions right now. Please try again."
      end

      return
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation).merge(force_password_reset: false))
      @user.password = @user.password_confirmation = nil
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def send_password_reset_instructions(user)
      mail = PasswordsMailer.reset(user)

      begin
        mail.deliver_later
        true
      rescue StandardError => enqueue_error
        Rails.logger.warn("[PasswordsController] Failed to enqueue password reset email for user_id=#{user.id}: #{enqueue_error.class}: #{enqueue_error.message}")

        begin
          mail.deliver_now
          true
        rescue StandardError => delivery_error
          Rails.logger.error("[PasswordsController] Failed to deliver password reset email for user_id=#{user.id}: #{delivery_error.class}: #{delivery_error.message}")
          false
        end
      end
    rescue StandardError => reset_error
      Rails.logger.error("[PasswordsController] Failed to build password reset email for user_id=#{user.id}: #{reset_error.class}: #{reset_error.message}")
      false
    end

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
