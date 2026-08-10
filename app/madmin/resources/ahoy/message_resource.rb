class Ahoy::MessageResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :to
  attribute :mailer
  attribute :subject
  attribute :sent_at
  attribute :opened_at
  attribute :clicked_at

  # Associations
  attribute :user
  attribute :newsletter

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
