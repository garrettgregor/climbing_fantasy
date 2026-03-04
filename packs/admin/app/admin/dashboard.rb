ActiveAdmin.register_page("Dashboard") do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    upcoming_events = Event.where(starts_on: Date.current..).order(starts_on: :asc).limit(5)
    recent_events = Event.completed.order(starts_on: :desc).limit(3)

    div do
      panel "Upcoming Events" do
        table_for upcoming_events do
          column(:name) { |event| link_to event.name, admin_event_path(event) }
          column :location
          column :status
          column :starts_on
        end
      end

      panel "Recent Events" do
        table_for recent_events do
          column(:name) { |event| link_to event.name, admin_event_path(event) }
          column :location
          column :status
          column "Ended On", :ends_on
        end
      end
    end

    div do
      panel "Stats" do
        div class: "space-y-2 p-4" do
          para "Seasons: #{Season.count}"
          para "Events: #{Event.count}"
          para "Athletes: #{Athlete.count}"
          para "Categories: #{Category.count}"
          para "Rounds: #{Round.count}"
          para "Results: #{RoundResult.count}"
        end
      end
    end
  end
end
