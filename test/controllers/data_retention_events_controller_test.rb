require "test_helper"

class DataRetentionEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @store_manager = users(:one)
    @admin = users(:administrator)
    @account_one = accounts(:one)
    @account_two = accounts(:two)
  end

  test "store manager sees retention events for their account" do
    sign_in_as(@store_manager)
    patch managed_account_url, params: { account_id: @account_one.id }

    account_one_event = DataRetentionEvent.create!(
      account: @account_one,
      actor: @store_manager,
      record_type: "Customer",
      record_id: customers(:one).id,
      event_type: "manual_hold_enabled",
      action_name: "manual_hold",
      details: "Hold enabled"
    )

    account_two_event = DataRetentionEvent.create!(
      account: @account_two,
      actor: users(:two),
      record_type: "Customer",
      record_id: customers(:two).id,
      event_type: "manual_hold_enabled",
      action_name: "manual_hold",
      details: "Hold enabled"
    )

    get data_retention_events_url

    assert_response :success
    assert_match "##{account_one_event.record_id}", response.body
    assert_no_match "##{account_two_event.record_id}", response.body
  end

  test "supports filtering by event type" do
    sign_in_as(@store_manager)
    patch managed_account_url, params: { account_id: @account_one.id }

    DataRetentionEvent.create!(
      account: @account_one,
      actor: @store_manager,
      record_type: "Customer",
      record_id: customers(:one).id,
      event_type: "manual_hold_enabled",
      action_name: "manual_hold",
      details: "manual-hold-details-should-not-appear"
    )

    DataRetentionEvent.create!(
      account: @account_one,
      actor: @store_manager,
      record_type: "Customer",
      record_id: customers(:one).id,
      event_type: "automated_archive",
      action_name: "archive",
      details: "Archived"
    )

    get data_retention_events_url(event_type: "automated_archive")

    assert_response :success
    assert_match "Automated archive", response.body
    assert_no_match "manual-hold-details-should-not-appear", response.body
  end

  test "admin can access retention events without selecting a store" do
    sign_in_as(@admin)

    get data_retention_events_url

    assert_response :success
  end
end