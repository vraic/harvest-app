namespace :data_protection do
  desc "Purge soft-deleted records past retention window"
  task purge_deleted_records: :environment do
    PurgeDeletedRecordsJob.perform_now
  end
end
