FactoryGirl.define do
  factory :group_subscription do
    association :user, factory: :user
    association :group_season, factory: :group_season
  end
end
