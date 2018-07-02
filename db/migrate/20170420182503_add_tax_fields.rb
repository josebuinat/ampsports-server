class AddTaxFields < ActiveRecord::Migration
  def change
    add_column :companies, :tax_rate, :decimal, precision: 5, scale: 4, null: false, default: 0

    reversible do |direction|
      direction.up do
        execute "UPDATE companies SET tax_rate = CASE WHEN company_business_type = 'Rekisteröity yhdistys' THEN 0 ELSE 0.1 END"
      end

      direction.down {}
    end
  end
end
