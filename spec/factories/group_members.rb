FactoryGirl.define do
  factory :group_member do
    association :group, factory: :group
    association :user, factory: :user
  end
end
