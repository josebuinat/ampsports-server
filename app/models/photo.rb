# represents a Venue photo
class Photo < ActiveRecord::Base
  # primary should be a column in db; however it is primary_photo_id on venue
  # therefore, for compatibility it's that hacky way of reassigning the primary photo
  # through this virtual attribute; has to be changed when we'll get rid of the old admin
  attr_reader :primary

  belongs_to :venue
  has_attached_file :image,
                    styles: {
                      medium: '800x800>#',
                      thumb: '200x200>#',
                      small: '100x100>#' },
                    default_style: :medium
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  after_create :make_primary
  after_save :process_primary_flag

  def primary=(value)
    @primary = value.to_s == 'true'
    process_primary_flag if persisted?
  end

  def make_primary
    venue.set_primary_photo if venue.primary_photo_id.nil?
  end

  def process_primary_flag
    if @primary
      # if venue is a new record (e.g. it is created altogether - cannot update column on unexisting record)
      # it will be saved by original venue.save in a controller
      if venue.persisted?
        venue.set_primary_photo(id)
      else
        venue.primary_photo_id = id
      end
    end
    @primary = nil
  end
end
