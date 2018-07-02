FactoryGirl.define do
  factory :review do
    rating 3.5
    text "test review for venue"
    association :author, factory: :user
    venue
  end
end
