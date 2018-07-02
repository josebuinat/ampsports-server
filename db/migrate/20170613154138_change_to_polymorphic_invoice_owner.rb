class ChangeToPolymorphicInvoiceOwner < ActiveRecord::Migration
  def change
    rename_column :invoices, :user_id, :owner_id
    change_column_null :invoices, :owner_id, false
    add_column :invoices, :owner_type, :string
    add_index :invoices, [:owner_id, :owner_type]

    execute("UPDATE invoices SET owner_type = 'User'")
  end
end
