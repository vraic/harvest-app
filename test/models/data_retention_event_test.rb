require "test_helper"

class DataRetentionEventTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    event = DataRetentionEvent.new(
      account: accounts(:one),
      actor: users(:one),
      record_type: "Customer",
      record_id: customers(:one).id,
      event_type: "manual_hold_enabled",
      action_name: "manual_hold",
      details: "Hold enabled"
    )

    assert event.valid?
  end

  test "rejects unsupported event type" do
    event = DataRetentionEvent.new(
      account: accounts(:one),
      record_type: "Customer",
      record_id: customers(:one).id,
      event_type: "unexpected",
      action_name: "manual_hold"
    )

    assert_not event.valid?
    assert_includes event.errors[:event_type], "is not included in the list"
  end
end
