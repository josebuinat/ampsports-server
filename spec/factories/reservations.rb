FactoryGirl.define do
  factory :reservation do
    price 20
    payment_type :unpaid
    booking_type :online
    user
    court

    start_time do
      # reservation_court = court || court_id ? Court.find_by(id: court_id) : nil
      timezone = court ? court.venue.timezone : attributes_for(:venue)[:timezone]
      Time.use_zone(timezone) {
        Time.current.advance(weeks: 2).beginning_of_week.at_noon
      }
    end

    end_time { start_time.advance(hours: 1) }

    to_create do |instance|
      Time.use_zone(instance.court.venue.timezone) do
        instance.save!
      end
    end

    trait :two_hours do
      end_time { start_time.advance(hours: 2) }
    end

    factory :novalidate_reservation do
      to_create {|instance| instance.save(validate: false) }
    end

    factory :usd_reservation do
      association :court, factory: :usd_court
    end

    trait :paid do
      payment_type :paid
      is_paid true
      billing_phase Reservation.billing_phases[:billed]
    end

    trait :for_group do
      association :user, factory: :group
    end

    factory :group_reservation, traits: [:for_group]
  end
end
