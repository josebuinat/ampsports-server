FactoryGirl.define do
  factory :coach do
    sequence(:email) { |n| "coach-#{n}@test.com" }
    password "testpassword"
    created_at DateTime.current
    confirmed_at DateTime.current
    first_name "Coach"
    last_name "Professional"
    experience 3

    trait :with_company do
      association :company, factory: :company
    end

    trait :available do
      transient do
        for_court nil
      end

      after(:create) do |coach, evaluator|
        court = evaluator.for_court
        raise '!!Pass "for_court: court" to ":available" coach!!' unless court

        create :coach_price_rate, coach: coach, venue: court.venue, sport_name: court.sport_name,
          start_time: Time.current.advance(months: -3), end_time: Time.current.advance(months: 3)
      end
    end
  end
end
