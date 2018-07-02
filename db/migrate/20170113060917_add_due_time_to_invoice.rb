class AddDueTimeToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :due_time, :datetime
  end
end
