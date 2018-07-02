FactoryGirl.define do
  factory :participation_credit do
    association :user, factory: :user
    association :company, factory: :company
    association :group_classification, factory: :group_classification
  end
end
