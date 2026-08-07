class AddClassificationToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :classification, :integer, default: 0, null: false
  end
end
