class Category < ApplicationRecord
  belongs_to :event
  has_many :rounds, dependent: :destroy

  enum :discipline, { boulder: 0, lead: 1, speed: 2, combined: 3, boulder_and_lead: 4 }
  enum :gender, { male: 0, female: 1, non_binary: 2, other: 3, mixed: 4 }
  enum :para_classification,
    {
      range_and_power: "Range and Power",
      blind_visual: "Blind/Visual Impairment",
      amputee_lower: "Amputee Lower",
      amputee_upper: "Amputee Upper",
    },
    prefix: :para
  enum :age_category,
    {
      open: "Open",
      u17: "U17",
      u19: "U19",
      u21: "U21",
    },
    default: :open

  validates :name, presence: true
  validates :discipline, presence: true
  validates :gender, presence: true
  validates :external_id, uniqueness: { scope: :event_id }, allow_nil: true

  HISTORICAL_AGE_MAPPINGS = {
    /youth b/i => :u17,
    /youth a/i => :u19,
    /junior/i => :u21,
    /u17/i => :u17,
    /u19/i => :u19,
    /u21/i => :u21,
  }.freeze

  def para?
    para_classification.present?
  end

  def canonical_age_category
    HISTORICAL_AGE_MAPPINGS.each { |pattern, key| return key if name.match?(pattern) }
    :open
  end

  class << self
    def ransackable_attributes(_auth_object = nil)
      ["name", "discipline", "gender", "age_category", "para_classification"]
    end

    def ransackable_associations(_auth_object = nil)
      ["event", "rounds"]
    end
  end
end

# == Schema Information
#
# Table name: categories
#
#  id                  :bigint           not null, primary key
#  age_category        :string           default("open"), not null
#  discipline          :integer          not null
#  gender              :integer          not null
#  name                :string           not null
#  para_classification :string
#  para_intensity      :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  event_id            :bigint           not null
#  external_id         :integer
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
