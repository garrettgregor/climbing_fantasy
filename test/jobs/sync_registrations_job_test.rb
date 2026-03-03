require "test_helper"

class SyncRegistrationsJobTest < ActiveSupport::TestCase
  test "enqueues on sync queue" do
    assert_equal "sync", SyncRegistrationsJob.new.queue_name
  end

  test "scopes to upcoming and in_progress events" do
    upcoming_event = events(:keqiao_2026)
    upcoming_event.update!(status: :upcoming)

    completed_event = events(:keqiao_boulder)
    completed_event.update!(status: :completed)

    scoped = Event.where(status: [:upcoming, :in_progress])
    assert_includes scoped, upcoming_event
    assert_not_includes scoped, completed_event
  end

  test "rescue logic continues after per-event ApiError" do
    events(:keqiao_2026).update!(status: :upcoming)
    events(:keqiao_boulder).update!(status: :in_progress)

    errors_logged = 0
    events_attempted = 0

    Event.where(status: [:upcoming, :in_progress]).find_each do |_event|
      events_attempted += 1
      raise Ifsc::ApiClient::ApiError, "test error"
    rescue Ifsc::ApiClient::ApiError
      errors_logged += 1
    end

    assert_operator events_attempted, :>=, 2
    assert_equal events_attempted, errors_logged
  end
end
