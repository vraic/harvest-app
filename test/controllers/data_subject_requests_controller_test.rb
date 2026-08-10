require "test_helper"

class DataSubjectRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrator)
    @store_manager = users(:one)
    @store_staff = users(:two)
    @request_one = data_subject_requests(:one)
    @request_two = data_subject_requests(:two)
  end

  test "store manager can get index" do
    sign_in_as @store_manager

    get data_subject_requests_url

    assert_response :success
  end

  test "store manager index only shows their own requests" do
    sign_in_as @store_manager

    own_request = DataSubjectRequest.create!(
      account: accounts(:one),
      requester: @store_manager,
      subject_user: users(:three),
      request_type: :access,
      request_summary: "Own request should be visible"
    )

    get data_subject_requests_url

    assert_response :success
    assert_select "a[href='#{data_subject_request_path(own_request)}']", text: "View"
    assert_select "a[href='#{data_subject_request_path(@request_one)}']", count: 0
    assert_select "td", text: @admin.name, count: 0
  end

  test "store manager can create data subject request" do
    sign_in_as @store_manager
    subject = users(:three)

    assert_difference("DataSubjectRequest.count") do
      post data_subject_requests_url, params: {
        data_subject_request: {
          request_type: "access",
          request_summary: "Please provide my personal data.",
          due_on: 30.days.from_now.to_date,
          subject_user_id: subject.id,
          legal_basis: "legal_obligation",
          subject_name: "Manual Subject Name",
          subject_email: "manual-subject@example.com"
        }
      }
    end

    request = DataSubjectRequest.order(:id).last
    assert_redirected_to data_subject_request_path(request)
    assert request.identity_verified?
    assert_equal subject.name, request.subject_name
    assert_equal subject.email_address, request.subject_email
    assert_equal "legal_obligation", request.legal_basis
  end

  test "non-admin create always uses currently selected account" do
    sign_in_as @store_manager

    assert_difference("DataSubjectRequest.count") do
      post data_subject_requests_url, params: {
        data_subject_request: {
          account_id: accounts(:two).id,
          request_type: "access",
          request_summary: "Should bind to current account",
          due_on: 30.days.from_now.to_date,
          subject_user_id: users(:three).id
        }
      }
    end

    request = DataSubjectRequest.order(:id).last
    assert_equal accounts(:one).id, request.account_id
  end

  test "store manager cannot view another requester request in same account" do
    sign_in_as @store_manager

    get data_subject_request_url(@request_one)

    assert_redirected_to root_path
    assert_equal I18n.t("unauthorized"), flash[:alert]
  end

  test "new form subject user options are limited to current account users" do
    sign_in_as @store_manager

    get new_data_subject_request_url

    assert_response :success
    assert_select "select[name='data_subject_request[subject_user_id]'] option" do |options|
      values = options.map { |option| option["value"] }.reject(&:blank?)

      assert_includes values, users(:one).id.to_s
      assert_includes values, users(:three).id.to_s
      assert_not_includes values, users(:two).id.to_s
    end
  end

  test "store manager cannot create request for subject user outside current account" do
    sign_in_as @store_manager

    assert_no_difference("DataSubjectRequest.count") do
      post data_subject_requests_url, params: {
        data_subject_request: {
          request_type: "access",
          request_summary: "Should fail for out-of-account subject",
          due_on: 30.days.from_now.to_date,
          subject_user_id: users(:two).id
        }
      }
    end

    assert_response :unprocessable_content
    assert_select "div", /Subject user/
  end

  test "new form does not ask for subject name and email" do
    sign_in_as @store_manager

    get new_data_subject_request_url

    assert_response :success
    assert_select "input[name='data_subject_request[subject_name]']", 0
    assert_select "input[name='data_subject_request[subject_email]']", 0
    assert_select "textarea[name='data_subject_request[legal_basis]']", 0
    assert_select "select[name='data_subject_request[legal_basis]']" do
      assert_select "option[value='consent']", text: "Consent"
      assert_select "option[value='contract']", text: "Contract"
      assert_select "option[value='legal_obligation']", text: "Legal obligation"
      assert_select "option[value='vital_interests']", text: "Vital interests"
      assert_select "option[value='public_task']", text: "Public task"
      assert_select "option[value='legitimate_interests']", text: "Legitimate interests"
    end
  end

  test "store manager can attach evidence files and append more on update" do
    sign_in_as @store_manager
    first_file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png")

    post data_subject_requests_url, params: {
      data_subject_request: {
        request_type: "access",
        request_summary: "Please provide my personal data.",
        due_on: 30.days.from_now.to_date,
        subject_user_id: @store_manager.id,
        evidence_files: [ first_file ]
      }
    }

    request = DataSubjectRequest.order(:id).last
    assert_equal 1, request.evidence_files.count

    second_file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png")
    patch data_subject_request_url(request), params: {
      data_subject_request: {
        decision_summary: "Evidence logged",
        evidence_files: [ second_file ]
      }
    }

    assert_redirected_to data_subject_request_path(request)
    assert_equal 2, request.reload.evidence_files.count
  end

  test "store staff cannot update request" do
    sign_in_as @store_staff

    patch data_subject_request_url(@request_two), params: {
      data_subject_request: {
        status: "completed",
        decision_summary: "Done"
      }
    }

    assert_redirected_to root_path
    assert_not @request_two.reload.completed?
  end

  test "admin can complete erasure request and archive subject user" do
    sign_in_as @admin
    subject = users(:three)

    request = DataSubjectRequest.create!(
      account: accounts(:one),
      requester: users(:one),
      subject_user: subject,
      request_type: :erasure,
      request_summary: "Delete data",
      offboarding_action: :archive
    )

    patch data_subject_request_url(request), params: {
      data_subject_request: {
        decision_summary: "Approved"
      },
      complete_request: "1"
    }

    assert_redirected_to data_subject_request_path(request)
    assert request.reload.completed?
    assert_nil User.find_by(id: subject.id)
  end
end
