require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "validates presence of name" do
    cat = Category.new(event: events(:innsbruck_boulder), discipline: :boulder, gender: :male)
    cat.name = nil
    assert_not cat.valid?
    assert_includes cat.errors[:name], "can't be blank"
  end

  test "discipline enum values" do
    assert_equal %w[boulder lead speed combined boulder_and_lead], Category.disciplines.keys
  end

  test "gender enum values" do
    assert_equal %w[male female non_binary other mixed], Category.genders.keys
  end

  test "age_category enum values" do
    assert_equal %w[open u17 u19 u21], Category.age_categories.keys
  end

  test "belongs to event" do
    cat = categories(:innsbruck_boulder_men)
    assert_equal events(:innsbruck_boulder), cat.event
  end

  test "has many rounds" do
    cat = categories(:innsbruck_boulder_men)
    assert_includes cat.rounds, rounds(:innsbruck_boulder_men_qual)
    assert_includes cat.rounds, rounds(:innsbruck_boulder_men_final)
  end

  test "unique external_id within event" do
    existing = categories(:innsbruck_boulder_men)
    duplicate = Category.new(
      event: existing.event,
      external_id: existing.external_id,
      name: "Duplicate",
      discipline: :boulder,
      gender: :male
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "has already been taken"
  end

  test "canonical_age_category maps Youth B to u17" do
    cat = Category.new(name: "Youth B - Men", discipline: :boulder, gender: :male)
    assert_equal :u17, cat.canonical_age_category
  end

  test "canonical_age_category maps Junior to u21" do
    cat = Category.new(name: "Junior - Women", discipline: :lead, gender: :female)
    assert_equal :u21, cat.canonical_age_category
  end

  test "canonical_age_category defaults to open" do
    cat = Category.new(name: "Boulder - Men", discipline: :boulder, gender: :male)
    assert_equal :open, cat.canonical_age_category
  end

  test "para? returns false when para_classification is nil" do
    cat = categories(:innsbruck_boulder_men)
    assert_not cat.para?
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
