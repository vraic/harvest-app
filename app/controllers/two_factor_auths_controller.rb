class TwoFactorAuthsController < ApplicationController
  before_action :set_user

  # GET /two_factor_auth
  def show
    @user.generate_otp_secret! if @user.otp_secret.blank?
    @qr_code = @user.otp_qr_code
  end

  # POST /two_factor_auth
  def create
    @user.reload
    respond_to do |format|
      if @user.validate_otp(params[:otp_code])
        if @user.update(otp_required_for_login: true)
          path = @user.onboarded? ? settings_path : onboarding_path
          format.html { redirect_to path, notice: "2FA enabled", status: :see_other }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :show, status: :unprocessable_content }
          format.json { render json: @user.errors, status: :unprocessable_content }
        end
      else
        format.html { redirect_to two_factor_auth_path, alert: "Invalid code", status: :see_other }
        format.json { render json: { error: "Invalid OTP code" }, status: :unprocessable_content }
      end
    end
  end

  # DELETE /two_factor_auth
  def destroy
    @user.update(otp_required_for_login: false, otp_secret: nil)
    respond_to do |format|
      format.html { redirect_to settings_path, notice: "2FA disabled", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_user
    @user = Current.user
  end
end
