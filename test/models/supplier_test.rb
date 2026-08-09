require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    ActsAsTenant.current_tenant = @account
  end

  test "retention hold requires non-past keep until date" do
    supplier = Supplier.new(
      account: @account,
      name: "Retention Supplier",
      retention_hold: true,
      retention_hold_until: 1.day.ago.to_date
    )

    assert_not supplier.valid?
    assert_includes supplier.errors[:retention_hold_until], "must be today or later"
  end

  test "retention hold helper reflects future and past hold dates" do
    supplier = suppliers(:one)
    supplier.update!(retention_hold: true, retention_hold_until: 2.days.from_now.to_date)

    assert supplier.retention_hold_active?(reference_time: Time.current)

    supplier.update_column(:retention_hold_until, 1.day.ago.to_date)
    assert_not supplier.retention_hold_active?(reference_time: Time.current)
  end
end
