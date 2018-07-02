class AddBicToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :company_bic, :string
  end
end
