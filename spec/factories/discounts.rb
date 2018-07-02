FactoryGirl.define do
  factory :discount do
    name { generate(:name) }
    value 50
    round false
    add_attribute :method, :percentage
  end
end
