require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "soft deletes user" do
    user = users(:one)
    user.destroy
    assert_not_nil user.deleted_at
    assert_nil User.find_by(id: user.id)
    assert_not_nil User.with_deleted.find_by(id: user.id)
  end

  test "really deletes user" do
    user = users(:one)
    user.destroy_fully!
    assert_nil User.with_deleted.find_by(id: user.id)
  end

  test "requires strong password" do
    user = users(:one)

    assert_not user.update(password: "password", password_confirmation: "password")
    assert_includes user.errors[:password], "is too weak. Please use a longer password with mixed characters."
  end

  test "generate_email_otp! generates a token with 3 numbers then 3 letters" do
    user = users(:one)
    user.generate_email_otp!
    token = user.email_otp_token

    assert_match /\A\d{3}[A-Z]{3}\z/, token, "Token #{token} does not match the required format: 3 numbers then 3 letters (uppercase)"
  end
end
