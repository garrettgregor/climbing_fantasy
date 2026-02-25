require "test_helper"

class CsvImporter::AthleteImporterTest < ActiveSupport::TestCase
  test "imports athletes from Kaggle CSV format" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99001,Test,Climber,25.0,male,USA,175.0,180.0,,1999-05-10
      99002,Another,Climber,22.0,female,GBR,162.0,165.0,,2002-03-15
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_difference "Athlete.count", 2 do
      CsvImporter::AthleteImporter.import(file.path)
    end

    athlete = Athlete.find_by(external_athlete_id: 99001)
    assert_equal "Test", athlete.first_name
    assert_equal "Climber", athlete.last_name
    assert_equal "USA", athlete.country_code
    assert_equal "male", athlete.gender
    assert_equal 175.0, athlete.height
    assert_equal 180.0, athlete.arm_span
    assert_equal Date.parse("1999-05-10"), athlete.birthday
  ensure
    file&.close
    file&.unlink
  end

  test "skips existing athletes by external_id (idempotent)" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99003,New,Climber,30.0,male,USA,180.0,185.0,,1994-01-01
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

  test "maps gender correctly for male and female" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99004,Male,Climber,25.0,male,USA,,,,
      99005,Female,Climber,25.0,female,USA,,,,
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::AthleteImporter.import(file.path)

    assert_equal "male", Athlete.find_by(external_athlete_id: 99004).gender
    assert_equal "female", Athlete.find_by(external_athlete_id: 99005).gender
  ensure
    file&.close
    file&.unlink
  end

  test "imports rows with unrecognized gender as other" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99006,Unknown,Gender,25.0,HORAK,CZE,,,,
      99007,Numeric,Gender,25.0,123,USA,,,,
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::AthleteImporter.import(file.path)

    assert_equal "other", Athlete.find_by(external_athlete_id: 99006).gender
    assert_equal "other", Athlete.find_by(external_athlete_id: 99007).gender
  ensure
    file&.close
    file&.unlink
  end

  test "handles blank height arm_span and birthday" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99008,Sparse,Data,25.0,male,USA,,,,
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::AthleteImporter.import(file.path)

    athlete = Athlete.find_by(external_athlete_id: 99008)
    assert_nil athlete.height
    assert_nil athlete.arm_span
    assert_nil athlete.birthday
  ensure
    file&.close
    file&.unlink
  end

  test "updates existing athlete with new data on reimport" do
    csv_content = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99009,Fill,In,25.0,female,FRA,,,,
    CSV

    file = Tempfile.new([ "athletes", ".csv" ])
    file.write(csv_content)
    file.rewind
    CsvImporter::AthleteImporter.import(file.path)
    file.close
    file.unlink

    athlete = Athlete.find_by(external_athlete_id: 99009)
    assert_nil athlete.height

    csv_content2 = <<~CSV
      athlete_id,firstname,lastname,age,gender,country,height,arm_span,paraclimbing_sport_class,birthday
      99009,Fill,In,25.0,female,FRA,165.0,168.0,,1999-06-01
    CSV

    file2 = Tempfile.new([ "athletes", ".csv" ])
    file2.write(csv_content2)
    file2.rewind

    assert_no_difference "Athlete.count" do
      CsvImporter::AthleteImporter.import(file2.path)
    end

    athlete.reload
    assert_equal 165.0, athlete.height
    assert_equal 168.0, athlete.arm_span
    assert_equal Date.parse("1999-06-01"), athlete.birthday
  ensure
    file2&.close
    file2&.unlink
  end
end
