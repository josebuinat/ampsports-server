class AddCachedDatesToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :cached_invoice_period_end, :string
    add_column :companies, :cached_invoice_period_start, :string
  end
end
