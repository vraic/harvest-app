class Customer::GocardlessSetupsController < ApplicationController
  before_action :require_account!

  def create
    customer = Customer.find_by!(user: Current.user, account: Current.account)
    result = Gocardless::SetupCustomer.call(customer:, bank_account_token: setup_params[:bank_account_token])

    customer.update!(
      gocardless_customer_id: result.customer_id,
      gocardless_mandate_id: result.mandate_id,
      gocardless_configured_at: Time.current
    )

    redirect_to new_order_path, notice: "GoCardless is now configured for future orders."
  rescue ActiveRecord::RecordInvalid
    redirect_to new_order_path, alert: "Unable to configure GoCardless."
  end

  private

  def setup_params
    params.fetch(:setup, {}).permit(:bank_account_token)
  end
end
