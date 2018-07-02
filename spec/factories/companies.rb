FactoryGirl.define do
  factory :company do
    company_legal_name 'Test Company'
    country_id 1 # Finland
    company_business_type 'OY'
    company_tax_id 'FI2381233'
    company_street_address 'Mannerheimintie 5'
    company_zip '00100'
    company_city 'Helsinki'
    company_website 'www.testcompany.com'
    company_phone '+3585094849438'
    company_iban 'GR16 0110 1250 0000 0001 2300 695'
    bank_name 'Big good bank'
    company_bic '0000'
    tax_rate 0.1

    factory :usd_company do
      currency 'usd'
    end

    factory :euro_company do
      currency 'eur'
    end

    factory :usa_company do
      currency 'usd'
      country_id 2
      usa_state 'CA'
      company_city 'San Jose'
      company_street_address '200 E Santa Clara St'
      company_zip '95113'
      company_iban '000123456789'
      usa_routing_number '110000000'
    end
  end
end
