class CreateSavedInvoiceUserConnections < ActiveRecord::Migration
  def change
    create_table :saved_invoice_user_connections do |t|
      t.references :user, index: true, foreign_key: true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
