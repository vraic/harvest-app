require "test_helper"

class LoyaltyCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:three)
    @account = accounts(:one)
    @card = loyalty_cards(:one)
    sign_in_as(@user)
    # Set the managed account session
    patch managed_account_url, params: { account_id: @account.id }
  end

  test "should get index and redirect to show if card exists" do
    get loyalty_cards_url
    assert_redirected_to loyalty_card_url(@card)
  end

  test "should get index if no card exists" do
    @user_without_card = users(:unassigned)
    Customer.create!(
      name: "New Customer",
      email_address: @user_without_card.email_address,
      account: @account,
      user: @user_without_card
    )
    sign_in_as(@user_without_card)
    patch managed_account_url, params: { account_id: @account.id }

    get loyalty_cards_url
    assert_response :success
    assert_select "main > div > div.w-full", count: 1
  end

  test "staff index without selected account is safe" do
    sign_out
    sign_in_as(users(:administrator))

    get loyalty_cards_url

    assert_response :success
    assert_select "main > div > div.w-full", count: 1
    assert_includes response.body, "No store selected"
    assert_not_includes response.body, loyalty_cards(:one).identifier
    assert_not_includes response.body, customers(:one).name
  end

  test "should get show" do
    get loyalty_card_url(@card)
    assert_response :success
  end

  test "should create loyalty_card" do
    @user_without_card = users(:unassigned)
    Customer.create!(
      name: "New Customer",
      email_address: @user_without_card.email_address,
      account: @account,
      user: @user_without_card
    )
    sign_in_as(@user_without_card)
    patch managed_account_url, params: { account_id: @account.id }

    assert_difference("LoyaltyCard.count") do
      post loyalty_cards_url
    end

    assert_redirected_to dashboard_path
    assert_equal "Enrolled", flash[:notice]
  end

  test "should get wallet" do
    get wallet_loyalty_card_url(@card)
    assert_response :success
    assert_equal "application/vnd.apple.pkpass", response.content_type
  end

  test "should get offline" do
    get offline_loyalty_card_url(@card)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end
end
