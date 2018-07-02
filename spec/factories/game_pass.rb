FactoryGirl.define do
  factory :game_pass do
    association :user, factory: :user
    association :venue, factory: :venue
    price 20

    trait :available do
      active true
      is_paid true
      remaining_charges 10
      total_charges 10
    end
  end
end
