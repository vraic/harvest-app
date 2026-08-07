class AddLocationToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :location, null: true, foreign_key: true
  end
end
