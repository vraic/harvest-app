require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:one)
    @customer = users(:three)
    @other_user = users(:two)
    @order = orders(:one)

    # Set current account for policy helpers
    Current.account = accounts(:one)
    ActsAsTenant.current_tenant = accounts(:one)
  end

  def test_scope
    scope = OrderPolicy::Scope.new(@admin, Order).resolve
    assert_includes scope, @order

    scope = OrderPolicy::Scope.new(@customer, Order).resolve
    assert_includes scope, @order # @order.customer is customers(:one), which belongs to users(:three)

    scope = OrderPolicy::Scope.new(@other_user, Order).resolve
    assert_not_includes scope, @order
  end

  def test_show
    assert OrderPolicy.new(@admin, @order).show?
    assert OrderPolicy.new(@customer, @order).show?
    assert_not OrderPolicy.new(@other_user, @order).show?
  end

  def test_create
    assert OrderPolicy.new(@admin, Order).create?
    assert OrderPolicy.new(@customer, Order).create?
  end

  def test_create_denies_customer_when_storefront_is_disabled
    account = accounts(:one)
    original_b2c = account.is_b2c
    original_b2b = account.is_b2b
    account.update!(is_b2c: false, is_b2b: false)
    Current.account = account
    ActsAsTenant.current_tenant = account

    assert_not OrderPolicy.new(@customer, Order).create?
  ensure
    account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
    Current.account = accounts(:one)
    ActsAsTenant.current_tenant = accounts(:one)
  end

  def test_create_allows_store_operator_customer_when_account_is_b2b
    supplier_account = accounts(:four)
    operator_account = accounts(:two)
    original_b2c = supplier_account.is_b2c
    original_b2b = supplier_account.is_b2b
    supplier_account.update!(is_b2c: false, is_b2b: true)

    operator_user = users(:two)
    customer_membership = ActsAsTenant.without_tenant do
      AccountUser.create!(account: supplier_account, user: operator_user, user_role: :customer)
    end
    supplier_authorization = ActsAsTenant.without_tenant do
      Supplier.create!(account: supplier_account, supplier_account: operator_account, name: operator_account.name, email_address: "supplier-authorized@example.com")
    end

    Current.account = supplier_account
    ActsAsTenant.current_tenant = supplier_account

    assert OrderPolicy.new(operator_user, Order).create?
  ensure
    supplier_authorization&.destroy!
    customer_membership&.destroy!
    supplier_account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
    Current.account = accounts(:one)
    ActsAsTenant.current_tenant = accounts(:one)
  end

  def test_create_denies_store_operator_customer_when_b2b_store_not_authorized
    supplier_account = accounts(:four)
    original_b2c = supplier_account.is_b2c
    original_b2b = supplier_account.is_b2b
    supplier_account.update!(is_b2c: false, is_b2b: true)

    operator_user = users(:two)
    customer_membership = ActsAsTenant.without_tenant do
      AccountUser.create!(account: supplier_account, user: operator_user, user_role: :customer)
    end

    Current.account = supplier_account
    ActsAsTenant.current_tenant = supplier_account

    assert_not OrderPolicy.new(operator_user, Order).create?
  ensure
    customer_membership&.destroy!
    supplier_account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
    Current.account = accounts(:one)
    ActsAsTenant.current_tenant = accounts(:one)
  end

  def test_update
    assert OrderPolicy.new(@admin, @order).update?
    assert_not OrderPolicy.new(@customer, @order).update?
  end

  def test_destroy
    assert OrderPolicy.new(@admin, @order).destroy?
    assert_not OrderPolicy.new(@customer, @order).destroy?
  end
end
