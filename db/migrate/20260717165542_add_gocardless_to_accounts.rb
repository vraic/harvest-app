class AddGocardlessToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :gocardless_access_token, :string
    add_column :accounts, :gocardless_mode, :integer, default: 0
  end
end
