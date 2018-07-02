FactoryGirl.define do
  sequence :phone_number do |n|
    1*(10**8) + n*(10**4) + n
  end

  factory :user do
    email { generate(:email) }
    password "12345678"
    password_confirmation "12345678"
    first_name { generate(:first_name) }
    last_name { generate(:last_name) }
    phone_number
    city 'Chikagostan'
    street_address 'Some address 5/6'
    zipcode '32454'
    confirmation_sent_at DateTime.new
    confirmed_at DateTime.new

    transient do
      provider nil
      uid nil
      unsubscribe_venue_emails nil
    end

    after(:build) do |user, evaluator|
      if evaluator.provider.present?
        user.social_accounts.build uid: evaluator.uid, provider: evaluator.provider
      end

      if evaluator.unsubscribe_venue_emails
        user.venue_user_connectors.first.update(email_subscription: false)
      end
    end

    trait :with_venues do
      transient do
        venue_count 1
      end

      after(:create) do |user, evaluator|
        create_list(:venue, evaluator.venue_count, :with_courts, users: [user])
        user.reload
      end
    end

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at nil
      password nil
      password_confirmation nil
    end

    trait :unconfirmed_with_password do
      confirmed_at { nil }
    end

    trait :no_password do
      password nil
      password_confirmation nil
    end

    trait :with_favourites do
      transient do
        favourites_count 2
      end

      after(:create) do |user, evaluator|
        create_list(:venue, evaluator.favourites_count, favourited_by: [user])
        user.reload
      end
    end

    trait :with_devices do
      transient do
        devices_count 1
      end

      after(:create) do |user, evaluator|
        create_list(:device, evaluator.devices_count, user: user)
        user.reload
      end
    end
  end

  sequence :email do |n|
    "play#{n}@playven.com"
  end

  sequence :first_name do |n|
    "Play#{n}"
  end

  sequence :last_name do |n|
    "Ven#{n}"
  end

end
