class OnboardingsController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user
    if params[:role] == "store_owner"
      @user.update!(onboarded: true)
      redirect_to new_account_path
    elsif params[:role] == "customer"
      @user.update!(onboarded: true)
      redirect_to dashboard_path
    else
      redirect_to onboarding_path, alert: "Select an option"
    end
  end
end
