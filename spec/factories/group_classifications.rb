FactoryGirl.define do
  factory :group_classification do
    name { generate(:name) }

    association :venue, factory: :venue

    price 20
    price_policy :hourly
  end
end
