class DataRetentionEventsController < ApplicationController
  before_action :require_account!

  def index
    events = policy_scope(DataRetentionEvent).includes(:account, :actor).recent

    if params[:event_type].present? && DataRetentionEvent::EVENT_TYPES.include?(params[:event_type])
      events = events.where(event_type: params[:event_type])
    end

    @pagy, @data_retention_events = pagy(events)
  end
end
