require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:competition)
  should have_many(:rounds)

  # Validations
  should validate_presence_of(:name)
  should validate_presence_of(:discipline)
  should validate_presence_of(:gender)

  # Enums
  test "discipline enum values" do
    assert_equal %w[boulder lead speed combined boulder_and_lead], Category.disciplines.keys
  end

  test "gender enum values" do
    assert_equal %w[male female], Category.genders.keys
  end

  test "unique external_category_id within competition" do
    existing = categories(:innsbruck_boulder_men)
    duplicate = Category.new(
      competition: existing.competition,
      external_category_id: existing.external_category_id,
      name: "Duplicate",
      discipline: :boulder,
      gender: :male
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_category_id], "has already been taken"
  end
end
