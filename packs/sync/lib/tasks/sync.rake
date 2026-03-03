namespace :sync do
  desc "Sync seasons and pending events from IFSC API"
  task seasons: :environment do
    SyncSeasonsJob.perform_now
  end

  desc "Sync registrations for upcoming/active events"
  task registrations: :environment do
    SyncRegistrationsJob.perform_now
  end

  desc "Sync results for active events"
  task results: :environment do
    SyncResultsJob.perform_now
  end
end
