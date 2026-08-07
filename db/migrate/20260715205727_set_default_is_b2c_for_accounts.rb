class SetDefaultIsB2cForAccounts < ActiveRecord::Migration[8.1]
  def change
    change_column_default :accounts, :is_b2c, from: false, to: true
  end
end
