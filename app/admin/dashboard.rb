# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "grid grid-cols-1 lg:grid-cols-2 gap-6" do
      div do
        panel "Recent Competitions" do
          table_for Competition.order(starts_on: :desc).limit(10) do
            column(:name) { |c| link_to c.name, admin_competition_path(c) }
            column :location
            column :discipline
            column :status
            column :starts_on
          end
        end
      end

      div do
        panel "Stats" do
          div class: "space-y-2 p-4" do
            para "Seasons: #{Season.count}"
            para "Competitions: #{Competition.count}"
            para "Athletes: #{Athlete.count}"
            para "Categories: #{Category.count}"
            para "Rounds: #{Round.count}"
            para "Results: #{RoundResult.count}"
          end
        end
      end
    end
  end
end
