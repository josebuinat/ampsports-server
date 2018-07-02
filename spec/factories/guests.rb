FactoryGirl.define do
  factory :guest do
    full_name { generate(:first_name) }
  end
end
