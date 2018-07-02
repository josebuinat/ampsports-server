class ChangeAmountPaidToDecimal < ActiveRecord::Migration
  def change
    change_column :reservations, :amount_paid, :decimal
  end
end
