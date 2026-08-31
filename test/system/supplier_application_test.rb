require "application_system_test_case"

class SupplierApplicationTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "New Supplier", email_address: "new_supplier_app@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong", onboarded: true, security_choice_made: true)
    @account_to_supply = accounts(:one)
  end

  test "new user can create a store and then apply as a supplier" do
    login_as(@user)
    visit dashboard_path

    # 1. Click Create a Store via settings
    visit settings_path
    click_on "Convert account to a store account"

    fill_in "Name", with: "My New Farm Shop"
    fill_in "Address", with: "123 Green Lane"
    click_on "Create Account"

    assert_text "Account created"

    # 3. Go to edit account and Stores We Supply tab
    @new_store = Account.find_by!(name: "My New Farm Shop")
    visit edit_account_path(@new_store)
    click_link "Stores We Supply"
    click_link "Supply A Store"

    select @account_to_supply.name, from: "Applying to Supply"

    click_on "Send Supplier Request"

    assert_text "Request sent"

    # Verify in DB
    request = SupplierRequest.last
    assert_equal "My New Farm Shop", request.sender_account.name
    assert_equal @account_to_supply, request.receiver_account
  end

  test "user with existing store can apply as supplier" do
    # Give user a store first
    @my_store = Account.create!(name: "Existing Store", owner: @user)

    login_as(@user)

    # 1. Go to edit account and Stores We Supply tab
    visit edit_account_path(@my_store)
    click_link "Stores We Supply"
    click_link "Supply A Store"

    # Select which store to supply
    select @account_to_supply.name, from: "Applying to Supply"

    click_on "Send Supplier Request"
    assert_text "Request sent"
  end

  test "user with multiple stores can choose which one to apply from" do
    @store1 = Account.create!(name: "Store Alpha", owner: @user)
    @store2 = Account.create!(name: "Store Beta", owner: @user)

    login_as(@user)

    # 1. Go to edit account for Store Beta
    visit edit_account_path(@store2)
    click_link "Stores We Supply"
    click_link "Supply A Store"

    # Select target
    select @account_to_supply.name, from: "Applying to Supply"

    # Now should be on the form with Store Beta as sender
    assert_text "Applying to Supply"
    assert_text "Account One"
    assert_text "Applying from Store"
    assert_text "Store Beta"

    click_on "Send Supplier Request"
    assert_text "Request sent"

    assert_equal @store2, SupplierRequest.last.sender_account
  end

  test "user who is customer of one store and manager of another can apply" do
    # 1. User is a customer of Store A
    @store_a = accounts(:one)
    AccountUser.create!(account: @store_a, user: @user, user_role: :customer)

    # 2. User is a manager of Store B
    @store_b = Account.create!(name: "My Management Store", owner: @user)

    login_as(@user)
    @target = accounts(:two)

    # 1. Go to edit account for My Management Store
    visit edit_account_path(@store_b)
    click_link "Stores We Supply"
    click_link "Supply A Store"

    # Select target
    select @target.name, from: "Applying to Supply"

    assert_text "Applying to Supply"
    assert_text "Account Two"
    assert_text "Applying from Store"
    assert_text "My Management Store"

    click_on "Send Supplier Request"
    assert_text "Request sent"
  end
end
