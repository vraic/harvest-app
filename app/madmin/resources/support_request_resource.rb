class SupportRequestResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :status
  attribute :message
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :expires_at
  attribute :received_outside_system
  attribute :authorization_received_outside_system
  attribute :received_outside_system_confirmed_at

  # Associations
  attribute :audits
  attribute :account
  attribute :requester
  attribute :received_outside_system_confirmed_by
  attribute :comments

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
