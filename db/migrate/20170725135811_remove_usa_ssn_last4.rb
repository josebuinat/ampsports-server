class RemoveUsaSsnLast4 < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Company.where(country_id: 2).find_each do |company|
          admin = company.admins.god.first
          admin.update_attribute :admin_ssn, company.usa_ssn_last_4
        end
      end
    end

    remove_column :companies, :usa_ssn_last_4, :string

    reversible do |dir|
      dir.down do
        Company.where(country_id: 2).find_each do |company|
          admin = company.admins.god.first
          company.update_attribute :usa_ssn_last_4, admin.admin_ssn
        end
      end
    end
  end
end
