FactoryGirl.define do
  factory :api_secret_key do
    sequence(:name) { |i| "test-application-#{i}" }
    key { SecureRandom.urlsafe_base64(nil, false) }
  end
end
