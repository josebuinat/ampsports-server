json.report do
  json.created_count @importer.created_count
  json.skipped_count @importer.skipped_count
  json.failed_count @importer.invalid_count
  json.failed_rows(@importer.invalid_rows) do |failed_row|
    json.user do
      json.partial! '/admin/users/base', user: failed_row
    end
    json.errors failed_row.errors
  end
end
