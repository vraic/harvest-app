require "test_helper"

class DataSubjectRequestTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @requester = users(:one)
    @admin = users(:administrator)
  end

  test "sets defaults for requested_at due_on and status" do
    request = DataSubjectRequest.create!(
      account: @account,
      requester: @requester,
      request_type: :access,
      request_summary: "Please provide my data."
    )

    assert request.received?
    assert request.identity_verified?
    assert request.requested_at.present?
    assert request.due_on.present?
  end

  test "requires subject user when offboarding action is requested" do
    request = DataSubjectRequest.new(
      account: @account,
      requester: @requester,
      request_type: :erasure,
      request_summary: "Delete my personal data.",
      offboarding_action: :archive
    )

    assert_not request.valid?
    assert_includes request.errors[:subject_user], "can't be blank"
  end

  test "accepts only known lawful bases" do
    invalid_request = DataSubjectRequest.new(
      account: @account,
      requester: @requester,
      request_type: :access,
      request_summary: "Please provide my data.",
      legal_basis: "data_subject_request"
    )

    assert_not invalid_request.valid?
    assert_includes invalid_request.errors[:legal_basis], "is not included in the list"

    valid_request = DataSubjectRequest.new(
      account: @account,
      requester: @requester,
      request_type: :access,
      request_summary: "Please provide my data.",
      legal_basis: "legal_obligation"
    )

    assert valid_request.valid?
  end

  test "mark_completed applies archive offboarding action" do
    subject = users(:three)
    request = DataSubjectRequest.create!(
      account: @account,
      requester: @requester,
      subject_user: subject,
      request_type: :erasure,
      request_summary: "Delete my personal data where possible.",
      decision_summary: "Approved",
      offboarding_action: :archive
    )

    request.mark_completed!(actor: @admin)

    assert request.reload.completed?
    assert_nil User.find_by(id: subject.id)
  end

  test "hard delete offboarding requires admin actor" do
    request = DataSubjectRequest.create!(
      account: @account,
      requester: @requester,
      subject_user: users(:three),
      request_type: :erasure,
      request_summary: "Delete my personal data.",
      decision_summary: "Approved",
      offboarding_action: :hard_delete
    )

    assert_raises(ArgumentError) do
      request.apply_offboarding_action!(actor: @requester)
    end
  end
end
