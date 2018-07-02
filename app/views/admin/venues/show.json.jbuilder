json.partial! 'base', venue: @venue

# small perversion to not reload the venue (because children (photos) change venue (primary_photo_id))
# will go away after we the DB structure to correct one
photos = @venue.photos.to_a
primary_photo = photos.find(&:primary) || photos.find { |x| x.id == @venue.primary_photo_id }
json.photos photos do |photo|
  json.partial! 'admin/venues/photos/base', photo: photo
  json.primary primary_photo == photo
end

json.settings do
  json.calendar do
    @venue.settings(:calendar).list.each do |setting|
      json.set! setting[:name], setting[:value]
    end
  end
end
