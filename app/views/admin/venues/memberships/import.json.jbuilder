json.report do
  json.created_count @importer.created_count
  json.skipped_count @importer.skipped_count
  json.failed_count @importer.invalid_count
  json.failed_rows(@importer.invalid_rows) do |failed_row|
    json.params failed_row[:params]
    json.errors failed_row[:membership].errors
  end
end
