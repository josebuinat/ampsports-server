FactoryGirl.define do
  factory :group do
    name { generate(:name) }
    participation_price 13
    max_participants 4
    skill_levels [5.0]

    association :venue, factory: :venue
    association :owner, factory: :user
    association :classification, factory: :group_classification

    trait :with_custom_biller do
      # have to pass `group` to group_custom_biller, because of `groups` presence validation
      after :build do |group|
        create :group_custom_biller, groups: [group]
      end
    end

    trait :seasonal do
      priced_duration :season
    end

    factory :seasonal_group, traits: [:seasonal]
  end
end
