# represents a venue group_classification
class GroupClassification < ActiveRecord::Base
  include Sortable

  belongs_to :venue
  has_many :group_classifications_connectors, dependent: :destroy
  has_many :groups, foreign_key: :classification_id
  has_many :participation_credits, dependent: :destroy

  validates :venue, :name, :price_policy, presence: true

  enum price_policy: %i(hourly session)

  def deletable?
    groups.none? && participation_credits.none?
  end

  def destroy
    return false unless deletable?

    super
  end

  def price_can_be_calculated?
    price.present? && price_policy.present?
  end

  def price_at(start_time, end_time)
    return price if session?
    duration_in_hours = (end_time - start_time) / 60 / 60

    (price || 0.to_d) * duration_in_hours
  end
end
