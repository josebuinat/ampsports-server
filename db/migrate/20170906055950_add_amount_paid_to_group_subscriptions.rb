class AddAmountPaidToGroupSubscriptions < ActiveRecord::Migration
  def change
    add_column :group_subscriptions, :amount_paid, :decimal, precision: 8, scale: 2
  end
end
