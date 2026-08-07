class AddPaymentsAndGocardlessSetup < ActiveRecord::Migration[8.1]
  def change
    change_table :customers, bulk: true do |t|
      t.string :gocardless_customer_id
      t.string :gocardless_mandate_id
      t.datetime :gocardless_configured_at
    end

    create_table :payments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.references :customer, null: false, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "GBP"
      t.string :provider_reference

      t.timestamps
    end
  end
end
