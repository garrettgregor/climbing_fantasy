namespace :import do
  desc "Import athletes from CSV file"
  task :athletes, [ :path ] => :environment do |_t, args|
    abort "Usage: rake import:athletes[path/to/file.csv]" unless args[:path]
    abort "File not found: #{args[:path]}" unless File.exist?(args[:path])

    puts "Importing athletes from #{args[:path]}..."
    CsvImporter::AthleteImporter.import(args[:path])
    puts "Done. Total athletes: #{Athlete.count}"
  end

  desc "Import results from CSV file"
  task :results, [ :path ] => :environment do |_t, args|
    abort "Usage: rake import:results[path/to/file.csv]" unless args[:path]
    abort "File not found: #{args[:path]}" unless File.exist?(args[:path])

    puts "Importing results from #{args[:path]}..."
    CsvImporter::ResultImporter.import(args[:path])
    puts "Done. Total results: #{RoundResult.count}"
  end
end
