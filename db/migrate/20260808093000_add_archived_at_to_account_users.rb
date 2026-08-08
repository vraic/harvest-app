class AddArchivedAtToAccountUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :account_users, :archived_at, :datetime
    add_index :account_users, :archived_at
  end
end
