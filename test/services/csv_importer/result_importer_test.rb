require "test_helper"

class CsvImporter::ResultImporterTest < ActiveSupport::TestCase
  test "creates Season Competition Category Round and RoundResult from CSV" do
    csv_content = <<~CSV
      athlete_id,rank,discipline,season,date,event_id,event_location,d_cat
      #{athletes(:kokoro_fujii).external_athlete_id},1,boulder,2023,2023-06-15,9999,Prague,8001
    CSV

    file = Tempfile.new([ "results", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_difference [ "Season.count", "Competition.count", "Category.count", "Round.count", "RoundResult.count" ] do
      CsvImporter::ResultImporter.import(file.path)
    end

    season = Season.find_by(year: 2023)
    assert_equal "IFSC World Cup 2023", season.name

    comp = Competition.find_by(external_event_id: 9999)
    assert_equal "Prague", comp.location
    assert_equal "boulder", comp.discipline
    assert_equal "completed", comp.status
    assert_equal season, comp.season

    category = comp.categories.first
    assert_equal "boulder", category.discipline
    assert_equal 8001, category.external_category_id
    assert_equal "male", category.gender

    round = category.rounds.first
    assert_equal "Overall", round.name
    assert_equal "final", round.round_type
    assert_equal "completed", round.status

    result = round.round_results.first
    assert_equal 1, result.rank
    assert_equal athletes(:kokoro_fujii), result.athlete
  ensure
    file&.close
    file&.unlink
  end

  test "idempotent import does not duplicate records" do
    csv_content = <<~CSV
      athlete_id,rank,discipline,season,date,event_id,event_location,d_cat
      #{athletes(:kokoro_fujii).external_athlete_id},1,boulder,2023,2023-06-15,9998,Berlin,8002
    CSV

    file = Tempfile.new([ "results", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::ResultImporter.import(file.path)

    assert_no_difference [ "Season.count", "Competition.count", "Category.count", "Round.count", "RoundResult.count" ] do
      CsvImporter::ResultImporter.import(file.path)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "maps boulder&lead to boulder_and_lead" do
    csv_content = <<~CSV
      athlete_id,rank,discipline,season,date,event_id,event_location,d_cat
      #{athletes(:janja_garnbret).external_athlete_id},1,boulder&lead,2023,2023-08-10,9997,Munich,8003
    CSV

    file = Tempfile.new([ "results", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::ResultImporter.import(file.path)

    comp = Competition.find_by(external_event_id: 9997)
    assert_equal "boulder_and_lead", comp.discipline

    category = comp.categories.first
    assert_equal "boulder_and_lead", category.discipline
  ensure
    file&.close
    file&.unlink
  end

  test "skips rows with unknown athlete" do
    csv_content = <<~CSV
      athlete_id,rank,discipline,season,date,event_id,event_location,d_cat
      999999,1,lead,2023,2023-06-15,9996,Tokyo,8004
    CSV

    file = Tempfile.new([ "results", ".csv" ])
    file.write(csv_content)
    file.rewind

    assert_no_difference "RoundResult.count" do
      CsvImporter::ResultImporter.import(file.path)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "multiple athletes in same event create separate results" do
    csv_content = <<~CSV
      athlete_id,rank,discipline,season,date,event_id,event_location,d_cat
      #{athletes(:kokoro_fujii).external_athlete_id},1,boulder,2023,2023-06-15,9995,Hachioji,8005
      #{athletes(:tomoa_narasaki).external_athlete_id},2,boulder,2023,2023-06-15,9995,Hachioji,8005
    CSV

    file = Tempfile.new([ "results", ".csv" ])
    file.write(csv_content)
    file.rewind

    CsvImporter::ResultImporter.import(file.path)

    round = Competition.find_by(external_event_id: 9995).categories.first.rounds.first
    assert_equal 2, round.round_results.count
  ensure
    file&.close
    file&.unlink
  end
end
