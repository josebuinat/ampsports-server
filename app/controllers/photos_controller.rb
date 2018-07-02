class PhotosController < ApplicationController
  include Gallery

  before_action :set_venue

  def create
    @venue.photos.create(image: params[:file])
    render json: { images: gallery_images(@venue) }
  end

  def destroy
    photo = Photo.find(params[:id]).destroy
    @venue.set_primary_photo if @venue.primary_photo_id == photo.id
    render json: { images: gallery_images(@venue) }
  end

  # user primary_photo_id not primary_photo
  # otherwise corrupt data
  def make_primary
    photo = Photo.find(params[:photo_id])
    @venue.set_primary_photo(photo.id)
    render json: { images: gallery_images(@venue) }
  end

  private

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end
end
