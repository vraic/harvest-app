class ChangeDefaultAccountClassificationToB2B < ActiveRecord::Migration[8.1]
  def change
    change_column_default :accounts, :is_b2c, from: true, to: false
    change_column_default :accounts, :is_b2b, from: false, to: true
  end
end
