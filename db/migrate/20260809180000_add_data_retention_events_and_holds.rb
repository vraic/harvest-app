class AddDataRetentionEventsAndHolds < ActiveRecord::Migration[8.0]
  def change
    create_table :data_retention_events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :event_type, null: false
      t.string :action_name, null: false
      t.text :details

      t.timestamps
    end

    add_index :data_retention_events, [ :account_id, :created_at ]
    add_index :data_retention_events, [ :record_type, :record_id ]
    add_index :data_retention_events, :event_type

    add_column :customers, :retention_hold, :boolean, default: false, null: false
    add_column :customers, :retention_hold_until, :date
    add_column :customers, :retention_hold_reason, :string
    add_index :customers, :retention_hold

    add_column :suppliers, :retention_hold, :boolean, default: false, null: false
    add_column :suppliers, :retention_hold_until, :date
    add_column :suppliers, :retention_hold_reason, :string
    add_index :suppliers, :retention_hold
  end
end
