class AddCountryIdToCompanyAndUser < ActiveRecord::Migration
  def change
    add_column :users, :default_country_id, :integer
    add_column :companies, :country_id, :integer, null: false, default: 1
    add_column :venues, :country_id, :integer, null: false, default: 1

    Company.all.each do |company|
      country = Country.find_country(company.company_country)
      if country # if no country was found it will be Finland (from default field value)
        company.update!(country_id: country.id)
        company.venues.each do |venue|
          venue.update!(country_id: country.id)
        end
      end
    end
  end
end
