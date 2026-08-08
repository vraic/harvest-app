class AllowNullAccountOnNoticedNotifications < ActiveRecord::Migration[8.1]
  def change
    change_column_null :noticed_notifications, :account_id, true
  end
end
