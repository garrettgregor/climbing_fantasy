class Category < ApplicationRecord
  belongs_to :event
  has_many :rounds, dependent: :destroy
  has_many :category_registrations, dependent: :destroy
  has_many :athletes, through: :category_registrations
  has_many :round_results, through: :rounds

  enum :discipline, { boulder: 0, lead: 1, speed: 2, combined: 3, boulder_and_lead: 4 }
  enum :gender, { male: 0, female: 1, non_binary: 2, other: 3, mixed: 4 }

  validates :name, presence: true
  validates :discipline, presence: true
  validates :gender, presence: true
  validates :external_id, uniqueness: { scope: :event_id }, allow_nil: true

  class << self
    def ransackable_attributes(_auth_object = nil)
      ["name", "discipline", "gender", "event_id"]
    end

    def ransackable_associations(_auth_object = nil)
      ["event", "rounds", "category_registrations", "athletes", "round_results"]
    end
  end
end

# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  discipline  :integer          not null
#  gender      :integer          not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  event_id    :bigint           not null
#  external_id :integer
#
# Indexes
#
#  index_categories_on_event_id                  (event_id)
#  index_categories_on_event_id_and_external_id  (event_id,external_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
