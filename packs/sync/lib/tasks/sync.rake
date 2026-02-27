namespace :sync do
  desc "One-time backfill of all historical IFSC results through 2025"
  task backfill_historical: :environment do
    scope = Event.completed
      .where(starts_on: ...Date.new(2026, 1, 1))
      .where(results_synced_at: nil)
    total = scope.count
    puts "Enqueueing BackfillEventJob for #{total} events..."
    scope.find_each { |e| BackfillEventJob.perform_later(e.id) }
    puts "Done. Monitor at /sidekiq."
  end
end
