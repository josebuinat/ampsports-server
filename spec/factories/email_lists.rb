FactoryGirl.define do
  factory :email_list, class: EmailList do
    name { generate(:email_list_name) }
    venue

    trait :with_users do
      transient do
        user_count 2
      end

      after(:create) do |email_list, evaluator|
        create_list(:user, evaluator.user_count, email_lists: [email_list], venues: [evaluator.venue])
        email_list.reload
      end
    end
  end

  sequence :email_list_name do |n|
    "Test email list #{n}"
  end
end
