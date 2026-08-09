module DataRetention
  class EventRecorder
    def self.record!(account:, record:, event_type:, action_name:, details: nil, actor: nil)
      DataRetentionEvent.create!(
        account: account,
        actor: actor,
        record_type: record.class.name,
        record_id: record.id,
        event_type: event_type,
        action_name: action_name,
        details: details
      )
    end
  end
end