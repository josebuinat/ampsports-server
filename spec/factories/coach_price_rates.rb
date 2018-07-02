FactoryGirl.define do
  factory :coach_price_rate, :class => Coach::PriceRate do
    venue
    coach
    sport_name :tennis
    rate 10.0

    start_time do
      Time.use_zone(venue.timezone) do
        Time.current.advance(weeks: 1).beginning_of_week.at_noon.utc
      end
    end
    end_time { start_time.advance(hours: 1) }
  end
end
