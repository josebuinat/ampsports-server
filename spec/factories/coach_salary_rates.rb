FactoryGirl.define do
  factory :coach_salary_rate, :class => Coach::SalaryRate do
    venue
    coach
    sport_name :tennis
    rate 10.0

    monday true
    start_time do
      Time.use_zone(venue.timezone) do
        Time.current.advance(days: 1).at_noon
      end
    end
    end_time { start_time.advance(hours: 1) }

    trait :all_weeks do
      monday true
      tuesday true
      wednesday true
      thursday true
      friday true
      saturday true
      sunday true
    end
  end
end
