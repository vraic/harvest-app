class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email_address
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :admin
  attribute :name
  attribute :deleted_at
  attribute :otp_secret
  attribute :otp_required_for_login
  attribute :email_otp_token
  attribute :email_otp_sent_at
  attribute :prefers_email_login
  attribute :security_choice_made
  attribute :onboarded
  attribute :force_password_reset
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false

  # Associations
  attribute :referral_codes
  attribute :referrals
  attribute :referral
  attribute :sessions
  attribute :account_users
  attribute :accounts
  attribute :customers
  attribute :suppliers
  attribute :tasks
  attribute :assigned_tasks
  attribute :orders
  attribute :notes
  attribute :support_requests
  attribute :notifications

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
