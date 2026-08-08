require "test_helper"
require "rake"

class UsersRakeTest < ActiveSupport::TestCase
  class FakeTTYInput
    def initialize(lines)
      @lines = lines
    end

    def tty?
      true
    end

    def gets
      @lines.shift
    end

    def noecho
      yield self
    end
  end

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("users:seed_super_user")
    @task = Rake::Task["users:seed_super_user"]
    @task.reenable
    @original_stdin = $stdin

    @original_env = {
      "SEED_EMAIL_ADDRESS" => ENV["SEED_EMAIL_ADDRESS"],
      "SEED_PASSWORD" => ENV["SEED_PASSWORD"],
      "SEED_NAME" => ENV["SEED_NAME"],
      "EMAIL_ADDRESS" => ENV["EMAIL_ADDRESS"],
      "PASSWORD" => ENV["PASSWORD"],
      "NAME" => ENV["NAME"]
    }
  end

  teardown do
    @task.reenable
    @original_env.each { |key, value| ENV[key] = value }
    $stdin = @original_stdin
  end

  test "seed_super_user creates a super user with forced password reset" do
    email = "seed-admin@example.com"
    password = "VeryStrongSuperUserPassword123!"

    ENV["EMAIL_ADDRESS"] = email
    ENV["PASSWORD"] = password
    ENV["NAME"] = "Seed Admin"
    ENV["SEED_EMAIL_ADDRESS"] = nil
    ENV["SEED_PASSWORD"] = nil
    ENV["SEED_NAME"] = nil

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
    ENV["SEED_EMAIL_ADDRESS"] = nil
    ENV["SEED_PASSWORD"] = nil
    ENV["SEED_NAME"] = nil

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

  test "seed_super_user prompts interactively when env vars are not provided" do
    email = "interactive-admin@example.com"
    password = "VeryStrongInteractivePassword123!"

    ENV["EMAIL_ADDRESS"] = nil
    ENV["PASSWORD"] = nil
    ENV["NAME"] = nil
    ENV["SEED_EMAIL_ADDRESS"] = nil
    ENV["SEED_PASSWORD"] = nil
    ENV["SEED_NAME"] = nil

    $stdin = FakeTTYInput.new([
      "#{email}\n",
      "Interactive Admin\n",
      "#{password}\n",
      "#{password}\n"
    ])

    output, = capture_io do
      assert_difference("User.where(email_address: '#{email}').count", 1) do
        @task.invoke
      end
    end

    user = User.find_by!(email_address: email)

    assert user.admin?
    assert user.force_password_reset?
    assert user.authenticate(password)
    assert_equal "Interactive Admin", user.name
    assert_includes output, "Email address:"
    assert_includes output, "Password:"
    assert_includes output, "Confirm password:"
    refute_includes output, password
  end

  test "seed_super_user aborts in non-interactive mode when env vars are missing" do
    ENV["EMAIL_ADDRESS"] = nil
    ENV["PASSWORD"] = nil
    ENV["NAME"] = nil
    ENV["SEED_EMAIL_ADDRESS"] = nil
    ENV["SEED_PASSWORD"] = nil
    ENV["SEED_NAME"] = nil

    $stdin = StringIO.new

    _, error_output = capture_io do
      assert_raises(SystemExit) { @task.invoke }
    end

    assert_includes error_output, "EMAIL_ADDRESS is required in non-interactive mode."
  end
end
