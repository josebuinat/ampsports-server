class AddPriceToClassifications < ActiveRecord::Migration
  def change
    add_column :group_classifications, :price, :decimal
    add_column :group_classifications, :price_policy, :integer, default: 0, null: false
  end
end
