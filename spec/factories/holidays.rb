FactoryGirl.define do
  factory :holiday do
    start_time { DateTime.tomorrow.noon.utc.change(hour: 6, minute: 0, second: 0) }
    end_time { start_time.advance(hours: 16) }

    trait :with_courts do
      transient do
        court_count 2
      end

      after(:build) do |holiday, evaluator|
        list = build_list(:court, evaluator.court_count, :with_prices, holidays: [holiday])
        holiday.courts = list
      end
    end
  end
end
