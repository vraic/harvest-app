require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one) # Account admin for account one
    @customer = customers(:one) # Customer in account one
    sign_in_as(@user)
  end

  test "should get index" do
    get customers_url
    assert_response :success
  end

  test "should get new" do
    get new_customer_url
    assert_response :success
    assert_select "select[name='customer[customer_account_id]']", 0

    sign_in_as(users(:administrator))
    get new_customer_url
    assert_response :success
    assert_select "select[name='customer[customer_account_id]']", 0
  end

  test "should create customer" do
    assert_difference("Customer.count") do
      post customers_url, params: { customer: { email_address: "new@example.com", name: "New Customer", phone: "555-1234" } }
    end

    assert_redirected_to customer_url(Customer.last)
    assert_equal accounts(:one).id, Customer.last.account_id
  end

  test "should show customer" do
    get customer_url(@customer)
    assert_response :success
  end

  test "should get edit" do
    get edit_customer_url(@customer)
    assert_response :success
  end

  test "should update customer" do
    patch customer_url(@customer), params: { customer: { name: "Updated Name" } }
    assert_redirected_to customer_url(@customer)
    assert_equal "Updated Name", @customer.reload.name
  end

  test "should destroy customer (soft delete)" do
    assert_difference("Customer.count", -1) do
      delete customer_url(@customer)
    end

    assert_redirected_to customers_url
    assert_not_nil Customer.with_deleted.find_by(id: @customer.id).deleted_at
  end

  test "should show archived customers when requested" do
    delete customer_url(@customer)

    get customers_url(view: "archived")

    assert_response :success
    assert_match Customer.with_deleted.find(@customer.id).name, response.body
  end

  test "should show archived customer record" do
    delete customer_url(@customer)

    get customer_url(@customer, view: "archived")

    assert_response :success
    assert_match Customer.with_deleted.find(@customer.id).name, response.body
  end

  test "should allow anonymising archived customer" do
    delete customer_url(@customer)

    patch anonymise_customer_url(@customer, view: "archived")

    assert_redirected_to customers_url(view: "archived")
    assert Customer.with_deleted.find(@customer.id).deleted?
  end

  test "should update customer retention hold" do
    assert_difference("DataRetentionEvent.count", 1) do
      patch update_retention_hold_customer_url(@customer), params: {
        customer: {
          retention_hold: "1",
          retention_hold_until: 1.year.from_now.to_date,
          retention_hold_reason: "Minor"
        }
      }
    end

    assert_redirected_to customer_url(@customer)
    @customer.reload
    assert @customer.retention_hold
    assert_equal "Minor", @customer.retention_hold_reason
    assert_equal "manual_hold_enabled", DataRetentionEvent.order(:id).last.event_type
  end

  test "should really destroy customer as account admin" do
    assert_difference("Customer.count", -1) do
      delete really_destroy_customer_url(@customer)
    end

    assert_redirected_to customers_url
    assert_nil Customer.with_deleted.find_by(id: @customer.id)
  end

  test "should not really destroy customer as standard user" do
    sign_in_as(users(:three)) # Standard user for account one
    assert_no_difference("Customer.count") do
      delete really_destroy_customer_url(@customer)
    end

    assert_redirected_to root_path # user_not_authorized redirects here
  end

  test "should enforce tenant isolation on index" do
    get customers_url
    assert_match customers(:one).name, response.body
    assert_no_match customers(:two).name, response.body
  end

  test "should enforce tenant isolation on show" do
    get customer_url(customers(:two))
    assert_response :not_found # acts_as_tenant raises RecordNotFound or scopes it
  end
end
