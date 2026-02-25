require "test_helper"

class CsvImporter::AthleteImporterTest < ActiveSupport::TestCase
  test "imports athletes from CSV with new external_ids" do
    csv_content = <<~CSV
      athlete_id,first_name,last_name,country,gender
      99001,Test,Climber,USA,M
      99002,Another,Climber,GBR,F
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_difference "Athlete.count", 2 do
      CsvImporter::AthleteImporter.import(file.path)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "skips existing athletes by external_id" do
    csv_content = <<~CSV
      athlete_id,first_name,last_name,country,gender
      99003,New,Climber,USA,M
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::AthleteImporter.import(file.path)

    assert_no_difference "Athlete.count" do
      CsvImporter::AthleteImporter.import(file.path)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "maps gender correctly" do
    csv_content = <<~CSV
      athlete_id,first_name,last_name,country,gender
      99004,Male,Climber,USA,M
      99005,Female,Climber,USA,F
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::AthleteImporter.import(file.path)

    male = Athlete.find_by(external_athlete_id: 99004)
    assert_equal "male", male.gender

    female = Athlete.find_by(external_athlete_id: 99005)
    assert_equal "female", female.gender
  ensure
    file&.close
    file&.unlink
  end
end
