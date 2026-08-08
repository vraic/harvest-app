class AddBusinessOverrideFieldsToSupportRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :support_requests, :received_outside_system, :boolean, null: false, default: false
    add_column :support_requests, :authorization_received_outside_system, :boolean, null: false, default: false
    add_column :support_requests, :received_outside_system_confirmed_at, :datetime
    add_column :support_requests, :received_outside_system_confirmed_by_id, :integer

    add_index :support_requests, :received_outside_system_confirmed_by_id, name: "index_support_requests_on_override_confirmer_id"
    add_foreign_key :support_requests, :users, column: :received_outside_system_confirmed_by_id
  end
end
