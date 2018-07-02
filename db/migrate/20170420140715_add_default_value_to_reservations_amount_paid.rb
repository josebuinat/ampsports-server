class AddDefaultValueToReservationsAmountPaid < ActiveRecord::Migration
  def change
    change_column_default :reservations, :amount_paid, 0.0
  end
end
