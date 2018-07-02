class AddAdditionalPhoneAndNoteToCustomers < ActiveRecord::Migration
  def change
    add_column :users, :additional_phone_number, :string
    add_column :users, :note, :text
  end
end
