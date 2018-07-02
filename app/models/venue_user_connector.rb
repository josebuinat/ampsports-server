class VenueUserConnector < ActiveRecord::Base
  belongs_to :user, required: true
  belongs_to :venue, required: true

  validates :user_id, uniqueness: { scope: :venue_id }, if: :user_id

  scope :subscription_enabled, -> { where(email_subscription: true).uniq }
end
