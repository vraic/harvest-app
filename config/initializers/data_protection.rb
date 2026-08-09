Rails.application.configure do
  config.x.data_protection.data_subject_request_due_days = ENV.fetch("DATA_SUBJECT_REQUEST_DUE_DAYS", 30).to_i
  config.x.data_protection.soft_delete_retention_days = ENV.fetch("SOFT_DELETE_RETENTION_DAYS", 90).to_i
end
