class DataSubjectRequestResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :request_type
  attribute :status
  attribute :requested_at
  attribute :due_on
  attribute :identity_verified
  attribute :subject_name
  attribute :subject_email
  attribute :request_summary
  attribute :legal_basis
  attribute :decision_summary
  attribute :exemption_reason
  attribute :offboarding_action
  attribute :offboarding_reason
  attribute :completion_evidence
  attribute :completed_at
  attribute :acted_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :evidence_files, index: false

  # Associations
  attribute :audits
  attribute :account
  attribute :requester
  attribute :subject_user
  attribute :acted_by

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Add actions to the resource's index page
  # collection_action do
  #   link_to "Bulk Import", bulk_import_path, class: "btn btn-secondary"
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
