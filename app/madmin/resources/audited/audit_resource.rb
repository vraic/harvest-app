class Audited::AuditResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :username
  attribute :action
  attribute :audited_changes
  attribute :version
  attribute :comment
  attribute :remote_address
  attribute :request_uuid
  attribute :created_at, form: false

  # Associations
  attribute :auditable
  attribute :user
  attribute :associated

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
