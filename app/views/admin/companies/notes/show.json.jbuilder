json.(@note, :id, :text, :created_at, :updated_at)
json.last_edited_by_full_name @note.last_edited_by&.full_name