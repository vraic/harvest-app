class ChangeAccountClassificationToBooleans < ActiveRecord::Migration[8.1]
  def up
    add_column :accounts, :is_b2c, :boolean, default: false, null: false
    add_column :accounts, :is_b2b, :boolean, default: false, null: false
    add_column :accounts, :is_internal, :boolean, default: false, null: false

    # Copy data using raw SQL to avoid dependency on model enum
    execute "UPDATE accounts SET is_b2c = 1 WHERE classification = 0"
    execute "UPDATE accounts SET is_b2b = 1 WHERE classification = 1"
    execute "UPDATE accounts SET is_internal = 1 WHERE classification = 2"

    remove_column :accounts, :classification
  end

  def down
    add_column :accounts, :classification, :integer, default: 0, null: false

    execute "UPDATE accounts SET classification = 0 WHERE is_b2c = 1"
    execute "UPDATE accounts SET classification = 1 WHERE is_b2b = 1 AND is_b2c = 0"
    execute "UPDATE accounts SET classification = 2 WHERE is_internal = 1 AND is_b2b = 0 AND is_b2c = 0"

    remove_column :accounts, :is_b2c
    remove_column :accounts, :is_b2b
    remove_column :accounts, :is_internal
  end
end
