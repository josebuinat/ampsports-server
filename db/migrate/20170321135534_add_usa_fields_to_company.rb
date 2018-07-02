class AddUsaFieldsToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :usa_state, :string
    add_column :companies, :usa_ssn_last_4, :string
    add_column :companies, :usa_routing_number, :string
  end
end
