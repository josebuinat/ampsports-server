FactoryGirl.define do
  factory :custom_invoice_component do
    name { generate(:name) }
    price 20.0
    vat_decimal 0.0
  end
end
