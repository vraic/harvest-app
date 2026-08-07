module Gocardless
  class SetupCustomer
    Result = Data.define(:customer_id, :mandate_id)

    def self.call(customer:, bank_account_token: nil)
      token = bank_account_token.presence || customer.id.to_s

      Result.new(
        customer_id: "gc-customer-#{customer.id}",
        mandate_id: "gc-mandate-#{token}"
      )
    end
  end
end
