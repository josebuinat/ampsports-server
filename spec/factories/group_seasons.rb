FactoryGirl.define do
  factory :group_season do
    association :group, factory: :seasonal_group

    start_date do
      Time.use_zone(venue.timezone) do
        Date.current
      end
    end
    end_date { start_date + 3.months }
  end
end
