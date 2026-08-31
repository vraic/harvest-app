require "test_helper"

class CustomerUserLinkingTest < ActionDispatch::IntegrationTest
  setup do
    @account_a = accounts(:one)
    @account_b = accounts(:two)
  end

  test "creating a customer links to existing user" do
    user = User.create!(name: "Bob", email_address: "bob@example.com", password: "ComplexPassword123!")

    customer = nil
    ActsAsTenant.with_tenant(@account_a) do
      customer = Customer.create!(name: "Bob Customer", email_address: "bob@example.com")
    end

    assert_equal user, customer.user
    assert_equal "bob@example.com", customer.email_address

    au = AccountUser.unscoped.find_by(account: @account_a, user: user)
    assert_not_nil au
    assert_equal "customer", au.user_role
  end

  test "creating a user links to existing customer and creates account_user" do
    customer_a = nil
    ActsAsTenant.with_tenant(@account_a) do
      customer_a = Customer.create!(name: "Bob A", email_address: "bob@example.com")
    end

    customer_b = nil
    ActsAsTenant.with_tenant(@account_b) do
      customer_b = Customer.create!(name: "Bob B", email_address: "bob@example.com")
    end

    assert_nil customer_a.user_id
    assert_nil customer_b.user_id

    user = User.create!(name: "Bob", email_address: "bob@example.com", password: "ComplexPassword123!")

    assert_equal user.id, customer_a.reload.user_id
    assert_equal user.id, customer_b.reload.user_id

    au_a = AccountUser.unscoped.find_by(account: @account_a, user: user)
    assert_not_nil au_a
    assert_equal "customer", au_a.user_role

    au_b = AccountUser.unscoped.find_by(account: @account_b, user: user)
    assert_not_nil au_b
    assert_equal "customer", au_b.user_role
  end

  test "syncing email from user to customers" do
    user = User.create!(name: "Bob", email_address: "bob@example.com", password: "ComplexPassword123!")
    customer_a = nil
    ActsAsTenant.with_tenant(@account_a) do
      customer_a = Customer.create!(name: "Bob A", email_address: "bob@example.com")
    end

    user.update!(email_address: "newbob@example.com")

    assert_equal "newbob@example.com", customer_a.reload.email_address
  end

  test "syncing email from customer to user and other customers" do
    user = User.create!(name: "Bob", email_address: "bob@example.com", password: "ComplexPassword123!")
    customer_a = nil
    ActsAsTenant.with_tenant(@account_a) do
      customer_a = Customer.create!(name: "Bob A", email_address: "bob@example.com")
    end
    customer_b = nil
    ActsAsTenant.with_tenant(@account_b) do
      customer_b = Customer.create!(name: "Bob B", email_address: "bob@example.com")
    end

    customer_a.update!(email_address: "changed@example.com")

    assert_equal "changed@example.com", user.reload.email_address
    assert_equal "changed@example.com", customer_b.reload.email_address
  end

  test "public signup creates user and logs in" do
    with_signup_invite_code("linking-secret") do
      assert_difference "User.count", 1 do
        post signup_path, params: {
          user: { name: "Alice", email_address: "alice@example.com", password: "ComplexPassword123!" },
          signup_invite_code: "linking-secret"
        }
      end
    end

    assert_redirected_to security_setup_path
  end

  test "public signup with account_id creates customer and account_user" do
    with_signup_invite_code("linking-secret") do
      assert_difference "User.count", 1 do
        assert_difference "Customer.count", 1 do
          assert_difference "AccountUser.count", 1 do
            post signup_path, params: {
              user: { name: "Alice", email_address: "alice@example.com", password: "ComplexPassword123!" },
              account_id: @account_a.id,
              signup_invite_code: "linking-secret"
            }
          end
        end
      end
    end

    user = User.find_by(email_address: "alice@example.com")
    customer = Customer.find_by(email_address: "alice@example.com", account: @account_a)

    assert_equal user, customer.user
    au = AccountUser.unscoped.find_by(account: @account_a, user: user)
    assert_equal "customer", au.user_role
    assert_redirected_to security_setup_path
  end

  private
    def with_signup_invite_code(code)
      original_code = ENV["SIGNUP_INVITE_CODE"]
      ENV["SIGNUP_INVITE_CODE"] = code

      yield
    ensure
      ENV["SIGNUP_INVITE_CODE"] = original_code
    end
end
