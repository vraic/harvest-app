require "test_helper"
require "rake"

class UsersRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("users:seed_super_user")
    @task = Rake::Task["users:seed_super_user"]
    @task.reenable

    @original_env = {
      "EMAIL_ADDRESS" => ENV["EMAIL_ADDRESS"],
      "PASSWORD" => ENV["PASSWORD"],
      "NAME" => ENV["NAME"]
    }
  end

  teardown do
    @task.reenable
    @original_env.each { |key, value| ENV[key] = value }
  end

  test "seed_super_user creates a super user with forced password reset" do
    email = "seed-admin@example.com"
    password = "VeryStrongSuperUserPassword123!"

    ENV["EMAIL_ADDRESS"] = email
    ENV["PASSWORD"] = password
    ENV["NAME"] = "Seed Admin"

    output, = capture_io do
      assert_difference("User.where(email_address: '#{email}').count", 1) do
        @task.invoke
      end
    end

    user = User.find_by!(email_address: email)

    assert user.admin?
    assert user.force_password_reset?
    assert user.authenticate(password)
    assert_match("Created super user #{email}", output)
    refute_includes output, password
  end

  test "seed_super_user updates an existing user idempotently" do
    user = users(:administrator)
    user.update!(admin: false, force_password_reset: false)

    new_password = "UpdatedSuperUserPassword123!"

    ENV["EMAIL_ADDRESS"] = user.email_address
    ENV["PASSWORD"] = new_password
    ENV["NAME"] = "Updated Admin"

    output, = capture_io do
      assert_no_difference("User.count") do
        @task.invoke
      end
    end

    user.reload

    assert user.admin?
    assert user.force_password_reset?
    assert user.authenticate(new_password)
    assert_equal "Updated Admin", user.name
    assert_match("Updated super user #{user.email_address}", output)
    refute_includes output, new_password
  end
end
