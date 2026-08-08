require "test_helper"

class SupportRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrator)
    @store_manager = users(:one)
    @account = accounts(:one)
    @support_request = support_requests(:one)
  end

  test "should get index as admin" do
    sign_in_as @admin
    get support_requests_url
    assert_response :success
  end

  test "should get index as store manager" do
    sign_in_as @store_manager
    get support_requests_url
    assert_response :success
  end

  test "should get new" do
    sign_in_as @store_manager
    get new_support_request_url
    assert_response :success
  end

  test "should create support_request" do
    sign_in_as @store_manager
    assert_difference("SupportRequest.count") do
      post support_requests_url, params: { support_request: { message: "New help request" } }
    end
    assert_redirected_to support_requests_url
  end

  test "admin can create business override support_request with immediate authorization" do
    sign_in_as @admin

    assert_difference("SupportRequest.count") do
      post support_requests_url, params: {
        support_request: {
          account_id: @account.id,
          message: "Telephone support authorization received",
          business_override: "1",
          business_override_confirmation: "1"
        }
      }
    end

    assert_redirected_to support_requests_url

    support_request = SupportRequest.order(:id).last
    assert support_request.accepted?
    assert support_request.active?
    assert support_request.received_outside_system?
    assert support_request.authorization_received_outside_system?
    assert_equal @admin.id, support_request.received_outside_system_confirmed_by_id
    assert support_request.received_outside_system_confirmed_at.present?
  end

  test "admin business override requires explicit confirmation" do
    sign_in_as @admin

    assert_no_difference("SupportRequest.count") do
      post support_requests_url, params: {
        support_request: {
          account_id: @account.id,
          message: "Telephone support authorization received",
          business_override: "1",
          business_override_confirmation: "0"
        }
      }
    end

    assert_response :unprocessable_content
    assert_match "Business override confirmation must be accepted", response.body
  end

  test "admin business override without migrated columns returns validation error instead of crashing" do
    sign_in_as @admin

    missing_columns = [
      "received_outside_system",
      "authorization_received_outside_system",
      "received_outside_system_confirmed_at",
      "received_outside_system_confirmed_by_id"
    ]

    original_column_names = SupportRequest.method(:column_names)
    SupportRequest.define_singleton_method(:column_names) { original_column_names.call - missing_columns }

    begin
      assert_no_difference("SupportRequest.count") do
        post support_requests_url, params: {
          support_request: {
            account_id: @account.id,
            message: "Telephone support authorization received",
            business_override: "1",
            business_override_confirmation: "1"
          }
        }
      end
    ensure
      SupportRequest.define_singleton_method(:column_names, original_column_names)
    end

    assert_response :unprocessable_content
    assert_match "Business override fields are unavailable", response.body
  end

  test "store manager cannot force business override flags" do
    sign_in_as @store_manager

    assert_difference("SupportRequest.count") do
      post support_requests_url, params: {
        support_request: {
          message: "Need access support",
          business_override: "1",
          business_override_confirmation: "1"
        }
      }
    end

    support_request = SupportRequest.order(:id).last
    assert support_request.pending?
    assert_not support_request.received_outside_system?
    assert_not support_request.authorization_received_outside_system?
    assert_nil support_request.received_outside_system_confirmed_by_id
  end

  test "should accept support_request" do
    sign_in_as @admin
    patch support_request_url(@support_request), params: { support_request: { status: "accepted" } }
    assert_redirected_to support_requests_url
    @support_request.reload
    assert @support_request.accepted?
    assert @support_request.expires_at.present?
  end

  test "should extend support_request" do
    @support_request.grant_authorization!
    sign_in_as @admin
    post extend_support_request_url(@support_request), params: { duration: 24, unit: "hours" }
    assert_redirected_to support_requests_url
  end

  test "should show support_request" do
    sign_in_as @admin
    get support_request_url(@support_request)
    assert_response :success
  end

  test "should create support_request_comment" do
    sign_in_as @store_manager
    assert_difference("SupportRequestComment.count") do
      post support_request_comments_url(@support_request), params: { support_request_comment: { body: "Follow up message" } }
    end
    assert_redirected_to support_request_url(@support_request)
  end

  test "admin should edit comment" do
    comment = SupportRequestComment.create!(support_request: @support_request, user: @store_manager, account: @account, body: "Old body")
    sign_in_as @admin
    patch support_request_comment_url(@support_request, comment), params: { support_request_comment: { body: "New body" } }
    assert_redirected_to support_request_url(@support_request)
    assert_equal "New body", comment.reload.body
  end
end
