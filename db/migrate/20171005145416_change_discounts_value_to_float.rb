class ChangeDiscountsValueToFloat < ActiveRecord::Migration
  def up
    change_column :discounts, :value, :float
    change_column_null :discounts, :value, false
  end

  def down
    change_column :discounts, :value, :integer
    change_column_null :discounts, :value, true
  end
end
