class AddConnectionTypeToSavedInvoiceUserConnections < ActiveRecord::Migration
  def change
    add_column :saved_invoice_user_connections, :connection_type, :integer, default: SavedInvoiceUserConnection.connection_types[:recent]
  end
end
