class FixBooleanNullFields < ActiveRecord::Migration
  def change
    change_column_null :participations, :is_paid, false, false
    change_column_null :participations, :cancelled, false, false
    change_column_null :participations, :refunded, false, false
    change_column_null :group_seasons, :current, false, false
    change_column_null :group_subscriptions, :is_paid, false, false
    change_column_null :group_subscriptions, :cancelled, false, false
    change_column_null :group_subscriptions, :refunded, false, false
    change_column :courts, :active, :boolean, null: false, default: false
    change_column :courts, :payment_skippable, :boolean, null: false, default: false
    change_column_null :courts, :private, false, false
    change_column :discounts, :round, :boolean, null: false, default: false
    change_column_null :game_passes, :active, false, false
    change_column_null :game_passes, :is_paid, false, false
    change_column_null :memberships, :invoice_by_cc, false, false
    change_column_null :reservations, :refunded, false, false
    change_column_null :reservations, :reselling, false, false
    change_column_null :reservations, :inactive, false, false
    change_column_null :venues, :allow_overlapping_resell, false, false
  end
end
