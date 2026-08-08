require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:one)
  end

  test "notifies the assignee when a task is created with a responsible user" do
    account = accounts(:one)
    manager = users(:one)
    assignee = users(:two)
    AccountUser.find_or_create_by!(account: account, user: assignee) { |au| au.user_role = :store_staff }

    assert_difference(-> { assignee.notifications.count }, 1) do
      assert_no_difference(-> { manager.notifications.count }) do
        Task.create!(
          account: account,
          title: "Assigned task",
          description: "Assigned task description",
          responsible_user: assignee,
          assigned_by: manager,
          due_date: 1.week.from_now.to_date
        )
      end
    end

    notification = assignee.notifications.order(created_at: :desc).first
    assert_equal "TaskAssignedNotifier", notification.event.type
    assert_equal account.id, notification.event.account_id
  end

  test "notifies all active staff when a task is created without a responsible user" do
    account = accounts(:one)
    manager = users(:one)
    staff_user = users(:two)
    customer_user = users(:three)

    AccountUser.find_or_create_by!(account: account, user: staff_user) { |au| au.user_role = :store_staff }
    AccountUser.find_or_create_by!(account: account, user: customer_user) { |au| au.user_role = :customer }

    assert_difference(-> { manager.notifications.count }, 1) do
      assert_difference(-> { staff_user.notifications.count }, 1) do
        assert_no_difference(-> { customer_user.notifications.count }) do
          Task.create!(
            account: account,
            title: "Unassigned task",
            description: "Unassigned task description",
            responsible_user: nil,
            assigned_by: manager,
            due_date: 1.week.from_now.to_date
          )
        end
      end
    end
  end

  test "valid task" do
    assert @task.valid?
  end

  test "invalid without title" do
    @task.title = nil
    assert_not @task.valid?
  end

  test "belongs to account" do
    assert_instance_of Account, @task.account
  end

  test "belongs to responsible user" do
    assert_instance_of User, @task.responsible_user
  end

  test "belongs to assigned by" do
    assert_instance_of User, @task.assigned_by
  end

  test "can have attachments" do
    @task.attachments.attach(io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "test.png", content_type: "image/png")
    assert @task.attachments.attached?
  end

  test "completion logic" do
    assert_not @task.completed?

    @task.complete!
    assert @task.completed?
    assert_not_nil @task.completed_at

    @task.incomplete!
    assert_not @task.completed?
    assert_nil @task.completed_at
  end

  test "completed and incomplete scopes" do
    @task.complete!
    assert_includes Task.completed, @task
    assert_not_includes Task.incomplete, @task

    @task.incomplete!
    assert_not_includes Task.completed, @task
    assert_includes Task.incomplete, @task
  end
end
