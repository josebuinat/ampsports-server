FactoryGirl.define do
  factory :coupon do
    sequence(:code) { |i| "couponNo#{i}" }
    description 'Some advantages you gain from this coupon'
  end
end
