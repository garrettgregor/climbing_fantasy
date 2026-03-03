require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "validates presence of name" do
    cat = Category.new(event: events(:keqiao_boulder), discipline: :boulder, gender: :male)
    cat.name = nil
    assert_not cat.valid?
    assert_includes cat.errors[:name], "can't be blank"
  end

  test "discipline enum values" do
    assert_equal ["boulder", "lead", "speed", "combined", "boulder_and_lead"], Category.disciplines.keys
  end

  test "gender enum values" do
    assert_equal ["male", "female", "non_binary", "other", "mixed"], Category.genders.keys
  end

  test "belongs to event" do
    cat = categories(:keqiao_boulder_men)
    assert_equal events(:keqiao_boulder), cat.event
  end

  test "has many rounds" do
    cat = categories(:keqiao_boulder_men)
    assert_includes cat.rounds, rounds(:keqiao_boulder_men_qual)
    assert_includes cat.rounds, rounds(:keqiao_boulder_men_final)
  end

  test "unique external_id within event" do
    existing = categories(:keqiao_boulder_men)
    duplicate = Category.new(
      event: existing.event,
      external_id: existing.external_id,
      name: "Duplicate",
      discipline: :boulder,
      gender: :male,
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "has already been taken"
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
