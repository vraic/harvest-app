class Ahoy::VisitResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :visit_token
  attribute :visitor_token
  attribute :ip
  attribute :user_agent
  attribute :referrer
  attribute :referring_domain
  attribute :landing_page
  attribute :browser
  attribute :os
  attribute :device_type
  attribute :country
  attribute :region
  attribute :city
  attribute :latitude
  attribute :longitude
  attribute :utm_source
  attribute :utm_medium
  attribute :utm_term
  attribute :utm_content
  attribute :utm_campaign
  attribute :app_version
  attribute :os_version
  attribute :platform
  attribute :started_at

  # Associations
  attribute :events
  attribute :user

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
