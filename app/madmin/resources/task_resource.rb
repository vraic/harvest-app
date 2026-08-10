class TaskResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :description
  attribute :due_date
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :completed_at
  attribute :attachments, index: false

  # Associations
  attribute :audits
  attribute :account
  attribute :responsible_user
  attribute :assigned_by

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
