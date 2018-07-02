FactoryGirl.define do
  factory :membership, class: Membership do
    user
    association :venue, factory: [:venue, :with_courts]

    start_time {
      in_venue_tz do
        Time.current.advance(weeks: -2).change(hour: 10)
      end
    }
    end_time { start_time.advance(months: 1, hours: 3) }
    price 20

    trait :with_reservations do
      after(:create) do |membership, evaluator|
        create(:reservation, user: membership.user,
                             court: membership.venue.courts.first,
                             start_time: membership.start_time.advance(weeks: 3),
                             membership: membership,
                             price: membership.price,
                             booking_type: :membership)
      end
    end
  end
end
