class CategoryRegistration < ApplicationRecord
  belongs_to :category
  belongs_to :athlete

  validates :athlete_id, uniqueness: { scope: :category_id }
end

# == Schema Information
#
# Table name: category_registrations
#
#  id                   :bigint           not null, primary key
#  registered_at_source :datetime
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  athlete_id           :bigint           not null
#  category_id          :bigint           not null
#
# Indexes
#
#  index_category_registrations_category_athlete_unique  (category_id,athlete_id) UNIQUE
#  index_category_registrations_on_athlete_id            (athlete_id)
#  index_category_registrations_on_category_id           (category_id)
#
# Foreign Keys
#
#  fk_rails_...  (athlete_id => athletes.id)
#  fk_rails_...  (category_id => categories.id)
#
