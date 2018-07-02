class GroupSubscriptionInvoiceComponent < ActiveRecord::Base
  include Taxable
  include Billable

  belongs_to :invoice
  belongs_to :group_subscription
  has_one :company, through: :invoice
  has_one :user, through: :group_subscription
  has_one :group, through: :group_subscription
  delegate :start_date, :end_date, to: :group_subscription

  # define product for Billable
  alias product group_subscription

  def group_name
    group.name
  end

  def self.build_from(group_subscriptions)
    group_subscriptions.map do |group_subscription|
      new(
        group_subscription: group_subscription,
        price: group_subscription.price
      )
    end
  end
end
