module Noticed
  class Event < ApplicationRecord
    include Deliverable
    include NotificationMethods
    include Translation
    include Rails.application.routes.url_helpers

    belongs_to :account
    belongs_to :record, polymorphic: true, optional: true
    has_many :notifications, dependent: :delete_all

    accepts_nested_attributes_for :notifications

    scope :newest_first, -> { order(created_at: :desc) }

    before_validation :assign_account_id, on: :create

    attribute :params, :json, default: {}

    scope :for_account, ->(account) { where(account_id: account.id) }

    if respond_to? :serialize
      if Rails.gem_version >= Gem::Version.new("7.1.0.alpha")
        serialize :params, coder: Coder
      else
        serialize :params, Coder
      end
    end

    private

    def assign_account_id
      self.account_id ||= params.is_a?(Hash) ? (params["account_id"] || params[:account_id]) : nil
    end
  end
end

ActiveSupport.run_load_hooks :noticed_event, Noticed::Event
