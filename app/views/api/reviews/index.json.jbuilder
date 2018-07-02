json.reviews(@reviews) do |review|
  json.id review.id
  json.venue_id review.venue_id
  json.rating review.rating
  json.text review.text
  json.author do
    json.id review.author.id
    json.first_name review.author.first_name.humanize
    json.last_name review.author.last_name.humanize
    json.email review.author.email
    json.profile_picture review.author.profile_picture
  end
  json.created_at review.created_at
  json.updated_at review.updated_at
end

json.current_page @reviews.current_page
json.total_pages @reviews.total_pages
json.total_reviews @reviews.total_entries
json.average_rating @venue.average_rating
