FactoryGirl.define do
  factory :invoice_component do
    invoice
    reservation

    price 20.0
    is_paid false
    is_billed false
  end
end
