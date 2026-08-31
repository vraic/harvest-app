class Customer::LoyaltyProgramsController < ApplicationController
  def index
    ActsAsTenant.without_tenant do
      # All active loyalty programs for B2C stores
      @loyalty_programs = LoyaltyProgram.joins(:account).where(accounts: { is_b2c: true }, active: true)

      # Customer records for the current user to check enrollment
      @customers = Customer.where(user_id: Current.user.id).includes(:account, :loyalty_card)
    end
  end

  def show
    ActsAsTenant.without_tenant do
      @loyalty_program = LoyaltyProgram.unscoped.find(params[:id])
      @customer = Customer.unscoped.find_by(account_id: @loyalty_program.account_id, user_id: Current.user.id)
      @loyalty_card = @customer&.loyalty_card

      if @loyalty_card.nil?
        redirect_to customer_loyalty_programs_path, alert: "Not enrolled"
        return
      end

      @transactions = @loyalty_card.loyalty_transactions.order(created_at: :desc).limit(20)
    end
  end

  def create
    ActsAsTenant.without_tenant do
      @loyalty_program = LoyaltyProgram.unscoped.find(params[:loyalty_program_id])

      # Find or create customer for this account
      @customer = Customer.unscoped.where(account_id: @loyalty_program.account_id, user_id: Current.user.id).first_or_create!(
        name: Current.user.name,
        email_address: Current.user.email_address
      )

      if @customer.loyalty_card.present?
        redirect_to customer_loyalty_programs_path, alert: "Already enrolled"
      else
        @loyalty_card = LoyaltyCard.create!(customer: @customer, loyalty_program: @loyalty_program)
        redirect_to customer_loyalty_program_path(@loyalty_program), notice: "Enrolled"
      end
    end
  end
end
