# Represents a discount that can be offered to customers.
class Discount < ActiveRecord::Base
  include TimeLimitations
  include CourtLimitations
  include Sortable
  has_many :users, through: :discount_connections
  has_many :discount_connections, dependent: :destroy
  belongs_to :venue

  scope :search, ->(term) { where('name ilike :term', term: "%#{term}%") }
  scope :for_venue, ->(venue) { where(venue: venue) }
  validates :method, presence: { message: 'Discount type cant be blank' }
  validates :name, presence: true
  validates :value, presence: true

  validate :correct_percentage

  enum method: [:percentage, :fixed, :fixed_price]

  def correct_percentage
    if percentage? && !(0..100).cover?(value)
      errors.add(:percentage, 'must be between 0 and 100')
    end
  end

  def apply(original_price, hours = nil)
    price = case method
            when 'percentage'
              original_price * (1.0 - value / 100.0)
            when 'fixed'
              [original_price - value, 0].max
            when 'fixed_price'
              value * (hours ? hours : 1)
            end

    round ? price.round : price
  end
end
