class SecuritySetupsController < ApplicationController
  def show
    @user = Current.user
  end

  def create
    @user = Current.user

    if params[:choice] == "email_login"
      @user.update!(prefers_email_login: true, security_choice_made: true)
      redirect_to onboarding_path, notice: "Email login enabled"
    else
      redirect_to password_security_setup_path
    end
  end

  def password
    @user = Current.user
  end

  def update_password
    @user = Current.user

    if @user.update(password_params.merge(prefers_email_login: false, security_choice_made: true))
      @user.password = @user.password_confirmation = nil
      redirect_to two_factor_security_setup_path, notice: "Password saved"
    else
      render :password, status: :unprocessable_content
    end
  end

  def two_factor
    @user = Current.user
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
