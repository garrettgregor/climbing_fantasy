Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      "sync_seasons" => {
        "class" => "SyncSeasonsJob",
        "cron" => "0 6 * * 1,4",
        "queue" => "sync",
        "description" => "Discover seasons and sync pending events (Mon+Thu 6am UTC)",
      },
      "sync_registrations" => {
        "class" => "SyncRegistrationsJob",
        "cron" => "0 7 * * *",
        "queue" => "sync",
        "description" => "Sync registrations for upcoming/active events (daily 7am UTC)",
      },
      "sync_results" => {
        "class" => "SyncResultsJob",
        "cron" => "0 */4 * * *",
        "queue" => "sync",
        "description" => "Poll results for active events (every 4 hours)",
      },
    )
  end
end
