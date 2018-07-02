module Gallery
  extend ActiveSupport::Concern

  def gallery_images(venue)
    venue.photos.map do |photo|
      photo_json = photo.attributes
      photo_json['url'] = photo.image.url(:thumb)
      photo_json['delete_url'] = venue_photo_path(venue, photo)
      photo_json['main_url'] = venue_photo_make_primary_path(venue, photo)
      photo_json['main'] = venue.primary_photo_id == photo.id
      photo_json
    end
  end
end
