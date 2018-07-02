FactoryGirl.define do
  factory :admin do
    sequence(:email) { |n| "admin-#{n}@test.com" }
    password "testpassword"
    created_at DateTime.current
    confirmed_at DateTime.current
    first_name "Admin"
    last_name "Professional"
    admin_birth_day 15
    admin_birth_month 9
    admin_birth_year 1980
    admin_ssn "311280-888Y"
    level :god
    locale :en

    trait :with_company do
      association :company, factory: :company
    end
  end
end
