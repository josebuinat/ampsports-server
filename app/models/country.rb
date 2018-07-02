class Country < ActiveYaml::Base
  include ActiveHash::Associations

  set_root_path "app/fixtures"
  set_filename "countries"

  fields :id, :iso_2, :name

  has_many :companies
  has_many :users

  class << self
    def find_country(country_name)
      return nil unless country_name
      find_by_id(country_name) || find_by_iso_2(country_name.upcase) || find_by_name(country_name)
    end
  end

  def code
    iso_2.downcase
  end

  def US?
    iso_2 == "US"
  end

  def FI?
    iso_2 == "FI"
  end
end
