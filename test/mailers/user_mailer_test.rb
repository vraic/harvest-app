require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "two_factor_code" do
    user = users(:one)
    user.update!(email_otp_token: "123456")
    mail = UserMailer.two_factor_code(user)
    assert_equal "Your 2FA Verification Code", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_match "12345678", mail.body.encoded
  end

  test "two_factor_code uses MAILER_FROM_ADDRESS when configured" do
    original_from = ENV["MAILER_FROM_ADDRESS"]
    ENV["MAILER_FROM_ADDRESS"] = "no-reply@example.test"

    user = users(:one)
    user.update!(email_otp_token: "123456")
    mail = UserMailer.two_factor_code(user)

    assert_equal [ "no-reply@example.test" ], mail.from
  ensure
    ENV["MAILER_FROM_ADDRESS"] = original_from
  end
end
