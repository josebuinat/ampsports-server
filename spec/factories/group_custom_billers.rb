FactoryGirl.define do
  factory :group_custom_biller do
    company_legal_name 'Test Company'
    company_business_type 'OY'
    company_tax_id 'FI2381233'
    bank_name 'best bank'
    company_bic '34536758345633'
    company_iban 'GR16 0110 1250 0000 0001 2300 695'
    country_id 1
    company_street_address 'Mannerheimintie 5'
    company_zip '00100'
    company_city 'Helsinki'
    company_website 'www.testcompany.com'
    company_phone '+3585094849438'
    invoice_sender_email 'test@test.test'
    tax_rate 0.1
  end
end
