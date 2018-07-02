class ParticipationInvoiceComponent < ActiveRecord::Base
  include Taxable
  include Billable

  belongs_to :invoice
  belongs_to :participation
  has_one :company, through: :invoice
  has_one :user, through: :participation
  has_one :reservation, through: :participation
  has_one :court, through: :reservation
  has_many :coaches, through: :reservation
  delegate :group, to: :reservation

  delegate :start_time, :end_time, to: :reservation
  delegate :court_name, to: :court

  # define product for Billable
  alias product participation

  def group_name
    group.name
  end

  def self.build_from(participations)
    participations.map do |participation|
      new(
        participation: participation,
        price: participation.price
      )
    end
  end
end
