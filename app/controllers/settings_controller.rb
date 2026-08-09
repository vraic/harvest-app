class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to settings_path, notice: "Personal information updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  def update_password
    if @user.authenticate(params[:current_password])
      if @user.update(password_params)
        @user.password = @user.password_confirmation = nil
        redirect_to settings_path, notice: "Password updated successfully."
      else
        render :show, status: :unprocessable_content
      end
    else
      @user.errors.add(:current_password, "is incorrect")
      render :show, status: :unprocessable_content
    end
  end

  def logout_sessions
    @user.sessions.where.not(id: Current.session.id).destroy_all
    redirect_to settings_path, notice: "Other sessions logged out."
  end

  def destroy
    request_account = offboarding_account

    create_self_service_erasure_request(request_account)

    if request_account.present?
      ActsAsTenant.with_tenant(request_account) { @user.destroy! }
    else
      @user.destroy!
    end

    reset_session
    redirect_to root_path, notice: "Account archived. Personal data is retained only where legally required and purged under policy."
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.require(:user).permit(:name, :email_address)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def create_self_service_erasure_request(request_account = offboarding_account)
    return if request_account.blank?

    DataSubjectRequest.create!(
      account: request_account,
      requester: @user,
      subject_user: @user,
      request_type: :erasure,
      status: :completed,
      requested_at: Time.current,
      due_on: Date.current,
      identity_verified: true,
      request_summary: "Self-service account closure requested from settings.",
      decision_summary: "Account archived via self-service settings flow.",
      offboarding_action: :archive,
      offboarding_reason: "Self-service account closure",
      completion_evidence: "User confirmed account closure in settings.",
      completed_at: Time.current,
      acted_by: @user,
      acted_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Data subject request log failed during settings destroy: #{e.message}")
  end

  def offboarding_account
    Current.account || @user.account_users.includes(:account).first&.account
  end
end
