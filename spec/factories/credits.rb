FactoryGirl.define do
  factory :credit do
    association :user, factory: :user
    association :company, factory: :company
  end
end
