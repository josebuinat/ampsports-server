FactoryGirl.define do
  factory :venue do
    venue_name "Test Venue"
    latitude "37.2155652"
    longitude "-121.8664214"
    description "Best Tennis Place In THe World"
    parking_info "You can park here"
    transit_info "Busses come here"
    website "www.tenniscompany.com"
    phone_number "+35840934052834"
    street "6604 Northridge Dr"
    city "San Jose"
    country_id 2
    zip "95120"
    timezone "Pacific Time (US & Canada)"
    booking_ahead_limit 365
    business_hours do
      { mon: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        tue: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        wed: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        thu: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        fri: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        sat: { opening: 21_600.0, closing: 79_200.0 },  # 6:00 - 22:00
        sun: { opening: 21_600.0, closing: 79_200.0 } } # 6:00 - 22:00
    end
    association :company, factory: :company

    trait :with_courts do
      transient do
        court_count 2
      end

      after(:create) do |venue, evaluator|
        create_list(:court, evaluator.court_count, :with_prices, venue: venue)
      end
    end

    trait :with_memberships do
      transient do
        membership_count 2
      end

      after(:create) do |venue, evaluator|
        create_list(:membership, evaluator.membership_count, venue: venue)
      end
    end

    trait :with_users do
      transient do
        user_count 1
      end

      after(:create) do |venue, evaluator|
        create_list(:user, evaluator.user_count, venues: [venue])
      end
    end

    trait :with_unconfirmed_users do
      transient do
        user_count 1
      end

      after(:create) do |venue, evaluator|
        create_list(:user, evaluator.user_count, :unconfirmed, venues: [venue])
      end
    end

    trait :searchable do
      after(:create) do |venue|
        venue.update_attribute :status, :searchable
      end
    end

    trait :prepopulated do
      after(:create) do |venue|
        venue.update_attribute :status, :prepopulated
      end
    end

    trait :with_photos do
      transient do
        photo_count 2
      end

      after(:create) do |venue, evaluator|
        create_list(:photo, evaluator.photo_count, venue: venue)
      end

    end

    factory :usd_venue do
      association :company, factory: :usd_company
    end
  end
end
