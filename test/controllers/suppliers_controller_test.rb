require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @supplier = suppliers(:one)
    @account = accounts(:one)
    sign_in_as(@user)
    # Set the tenant
    patch managed_account_url, params: { account_id: @account.id }
  end

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should get new" do
    get new_supplier_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='supplier[entry_mode]'][value='platform_store']"
    assert_select "input[name='supplier[entry_mode]'][value='manual_entry']"
    assert_select "select[name='supplier[supplier_account_id]']"
    assert_select "input[name='supplier[name]']"
    assert_select "input[name='supplier[email_address]']"

    # As admin
    sign_in_as(users(:administrator))
    get new_supplier_url
    assert_response :success
    assert_select "select[name='supplier[supplier_account_id]']"
    assert_select "select[name='supplier[account_id]']", 0
  end

  test "should create supplier from selected store" do
    supplier_store = accounts(:two)

    assert_difference("Supplier.count") do
      post suppliers_url, params: { supplier: { entry_mode: "platform_store", supplier_account_id: supplier_store.id } }
    end

    created_supplier = Supplier.last
    assert_equal supplier_store.id, created_supplier.supplier_account_id
    assert_equal supplier_store.name, created_supplier.name
    assert_equal supplier_store.owner.email_address, created_supplier.email_address
    assert_equal @account.id, created_supplier.account_id

    assert_redirected_to supplier_url(created_supplier)
  end

  test "should create supplier with manual entry" do
    supplier_store = accounts(:two)

    assert_difference("Supplier.count") do
      post suppliers_url, params: {
        supplier: {
          entry_mode: "manual_entry",
          supplier_account_id: supplier_store.id,
          name: "Manual Supplier",
          email_address: "manual@supplier.com",
          phone: "555-3333"
        }
      }
    end

    created_supplier = Supplier.last
    assert_nil created_supplier.supplier_account_id
    assert_equal "Manual Supplier", created_supplier.name
    assert_equal "manual@supplier.com", created_supplier.email_address
    assert_equal "555-3333", created_supplier.phone

    assert_redirected_to supplier_url(Supplier.last)
  end

  test "should require a selected store in platform mode" do
    assert_no_difference("Supplier.count") do
      post suppliers_url, params: { supplier: { entry_mode: "platform_store", supplier_account_id: "" } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation", text: /Supplier account must be selected/
  end

  test "should show supplier" do
    get supplier_url(@supplier)
    assert_response :success
  end

  test "should get edit" do
    get edit_supplier_url(@supplier)
    assert_response :success
    assert_select "form"
    assert_select "input[name='supplier[name]']"
  end

  test "should update supplier" do
    patch supplier_url(@supplier), params: { supplier: { name: "Updated" } }
    assert_redirected_to supplier_url(@supplier)
    assert_equal "Updated", @supplier.reload.name
  end

  test "should destroy supplier" do
    assert_difference("Supplier.count", -1) do
      delete supplier_url(@supplier)
    end
    assert_redirected_to suppliers_url
  end

  test "should get inventory" do
    get inventory_supplier_url(@supplier)
    assert_response :success
  end
end
