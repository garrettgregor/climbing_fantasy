require "test_helper"

class AthleteTest < ActiveSupport::TestCase
  # Associations
  should have_many(:round_results)

  # Validations
  should validate_presence_of(:first_name)
  should validate_presence_of(:last_name)
  should validate_presence_of(:country_code)
  should validate_presence_of(:gender)
  should validate_length_of(:country_code).is_at_most(3)
  should validate_uniqueness_of(:external_athlete_id).allow_nil

  # Enums
  test "gender enum values" do
    assert_equal %w[male female], Athlete.genders.keys
  end

  test "athlete has expected attributes" do
    athlete = athletes(:janja_garnbret)
    assert_equal "Janja", athlete.first_name
    assert_equal "Garnbret", athlete.last_name
    assert_equal "SLO", athlete.country_code
    assert_equal "female", athlete.gender
  end
end
