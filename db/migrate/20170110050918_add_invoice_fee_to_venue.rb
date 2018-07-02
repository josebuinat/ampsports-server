class AddInvoiceFeeToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :invoice_fee, :decimal, precision: 8, scale: 2
  end
end
