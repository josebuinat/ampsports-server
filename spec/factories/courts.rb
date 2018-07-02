FactoryGirl.define do
  factory :court do
    sport_name :tennis
    court_description { generate(:description) }
    duration_policy 60
    start_time_policy 0
    active true
    venue
    index 0
    indoor false

    factory :usd_court do
      association :venue, factory: :usd_venue
    end
  end

  sequence :name do |n|
    "Court #{n}"
  end

  sequence :description do |n|
    "Court description #{n}"
  end

  trait :with_holidays do
    transient do
      holidays_count 2
    end

    after(:create) do |court, evaluator|
      create_list(:holiday, evaluator.holidays_count, courts: [court])
    end
  end

  trait :with_prices do
    transient do
      price_count 1
    end

    after(:create) do |court, evaluator|
      create_list(:filled_price, evaluator.price_count, courts: [court])
    end
  end

end
