require "test_helper"

class SyncResultsJobTest < ActiveSupport::TestCase
  test "enqueues on sync queue" do
    assert_equal "sync", SyncResultsJob.new.queue_name
  end

  test "scopes to in_progress and needs_results events" do
    in_progress_event = events(:keqiao_2026)
    in_progress_event.update!(status: :in_progress)

    needs_results_event = events(:keqiao_boulder)
    needs_results_event.update!(status: :completed, sync_state: :needs_results)

    completed_event = events(:wujiang_lead_speed)
    completed_event.update!(status: :completed, sync_state: :synced)

    scoped = Event.where(status: :in_progress).or(Event.where(sync_state: :needs_results))
    assert_includes scoped, in_progress_event
    assert_includes scoped, needs_results_event
    assert_not_includes scoped, completed_event
  end

  test "is no-op when no active events" do
    Event.find_each { |e| e.update!(status: :completed, sync_state: :synced) }

    scoped = Event.where(status: :in_progress).or(Event.where(sync_state: :needs_results))
    assert_empty scoped
  end

  test "rescue logic continues after per-event ApiError" do
    events(:keqiao_2026).update!(status: :in_progress)
    events(:keqiao_boulder).update!(status: :in_progress)

    errors_logged = 0
    events_attempted = 0

    Event.where(status: :in_progress).find_each do |_event|
      events_attempted += 1
      raise Ifsc::ApiClient::ApiError, "test error"
    rescue Ifsc::ApiClient::ApiError
      errors_logged += 1
    end

    assert_operator events_attempted, :>=, 2
    assert_equal events_attempted, errors_logged
  end
end
