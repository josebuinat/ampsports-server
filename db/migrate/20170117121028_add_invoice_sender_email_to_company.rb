class AddInvoiceSenderEmailToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :invoice_sender_email, :string
  end
end
