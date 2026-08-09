class CreateDataSubjectRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :data_subject_requests do |t|
      t.references :account, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :subject_user, foreign_key: { to_table: :users }

      t.integer :request_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :requested_at, null: false
      t.date :due_on, null: false
      t.boolean :identity_verified, null: false, default: false

      t.string :subject_name
      t.string :subject_email
      t.text :request_summary, null: false
      t.text :legal_basis
      t.text :decision_summary
      t.text :exemption_reason

      t.integer :offboarding_action, null: false, default: 0
      t.string :offboarding_reason
      t.text :completion_evidence
      t.datetime :completed_at
      t.references :acted_by, foreign_key: { to_table: :users }
      t.datetime :acted_at

      t.timestamps
    end

    add_index :data_subject_requests, [ :account_id, :status ]
    add_index :data_subject_requests, [ :account_id, :due_on ]
    add_index :data_subject_requests, :request_type
  end
end
