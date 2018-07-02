class AddBankNameToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :bank_name, :string
  end
end
