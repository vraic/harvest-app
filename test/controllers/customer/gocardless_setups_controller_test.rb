require "test_helper"

class Customer::GocardlessSetupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = users(:three)
    @customer = customers(:one)
    sign_in_as(@customer_user)
  end

  test "customer can configure gocardless once for future checkouts" do
    assert_nil @customer.gocardless_mandate_id

    post customer_gocardless_setup_path, params: {
      setup: {
        bank_account_token: "BA-001"
      }
    }

    assert_redirected_to new_order_path

    @customer.reload
    assert_equal "gc-customer-#{@customer.id}", @customer.gocardless_customer_id
    assert_equal "gc-mandate-BA-001", @customer.gocardless_mandate_id
    assert_not_nil @customer.gocardless_configured_at
  end
end
