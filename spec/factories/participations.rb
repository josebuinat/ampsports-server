FactoryGirl.define do
  factory :participation do
    association :user, factory: :user
    association :reservation, factory: :group_reservation
  end
end
