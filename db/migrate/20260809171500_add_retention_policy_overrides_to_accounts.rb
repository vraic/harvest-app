class AddRetentionPolicyOverridesToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :inactivity_retention_years_override, :integer
    add_column :accounts, :soft_delete_retention_days_override, :integer
    add_column :accounts, :inactive_customer_retention_action, :string
    add_column :accounts, :inactive_supplier_retention_action, :string
  end
end
