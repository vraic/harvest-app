require "test_helper"

class NewsletterLockingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @newsletter = Newsletter.create!(
      account: @account,
      subject: "Test Newsletter",
      content: "Hello world",
      target: "everyone"
    )
    sign_in_as(@user)
  end

  test "can deliver a newsletter for the first time" do
    assert_enqueued_jobs 1 do
      post deliver_newsletter_url(@newsletter)
    end

    assert_redirected_to newsletter_url(@newsletter)
    @newsletter.reload
    assert @newsletter.sent?
  end

  test "cannot edit a sent newsletter" do
    @newsletter.update!(sent_at: Time.current)

    get edit_newsletter_url(@newsletter)
    assert_redirected_to newsletter_url(@newsletter)
    follow_redirect!
    assert_match "Already sent", response.body
  end

  test "cannot update a sent newsletter" do
    @newsletter.update!(sent_at: Time.current)

    patch newsletter_url(@newsletter), params: { newsletter: { subject: "New Subject" } }
    assert_redirected_to newsletter_url(@newsletter)
    follow_redirect!
    assert_match "Already sent", response.body

    @newsletter.reload
    assert_equal "Test Newsletter", @newsletter.subject
  end

  test "cannot deliver a sent newsletter again" do
    @newsletter.update!(sent_at: Time.current)

    assert_no_enqueued_jobs do
      post deliver_newsletter_url(@newsletter)
    end

    assert_redirected_to newsletter_url(@newsletter)
    follow_redirect!
    assert_match "Already sent", response.body
  end

  test "cannot destroy a sent newsletter" do
    @newsletter.update!(sent_at: Time.current)

    assert_no_difference("Newsletter.count") do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to newsletter_url(@newsletter)
    follow_redirect!
    assert_match "Already sent", response.body
  end

  test "uses prefixed IDs" do
    assert @newsletter.to_param.start_with?("nl_")
  end
end
