FactoryGirl.define do

  factory :custom_mail do
    from 'support@playven.com'
    subject 'Something important'
    body 'Some long text'
    venue

    trait :with_email_list do
      after(:create) do |custom_mail, evaluator|
        create_list(:email_list, 1, custom_mail: custom_mail, venue: evaluator.venue)
        custom_mail.reload
      end
    end
  end
end
