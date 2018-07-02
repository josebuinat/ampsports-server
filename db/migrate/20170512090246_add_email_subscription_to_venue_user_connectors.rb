class AddEmailSubscriptionToVenueUserConnectors < ActiveRecord::Migration
  def change
    add_column :venue_user_connectors, :email_subscription, :boolean, null: false, default: true
  end
end
