FactoryGirl.define do
  factory :activity_log do
    company
    activity_time DateTime.current

    trait :with_admin do
      association :actor, factory: :admin
      actor_name { actor.full_name }
    end

    trait :with_user do
      association :actor, factory: :user
      actor_name { actor.full_name }
    end

    before :create do |activity_log, evaluator|
      activity_log.build_payload_details
    end

    factory :reservation_activity_log do
      activity_type 'reservation_created'
      after :build do |activity_log, evaluator|
        reservation = FactoryGirl.create :novalidate_reservation, court: activity_log.company.courts.first
        activity_log.payloads = [reservation]
      end
    end

    factory :membership_activity_log do
      activity_type 'membership_created'
      after :build do |activity_log, evaluator|
        membership = FactoryGirl.create :membership, venue: activity_log.company.venues.first
        activity_log.payloads = [membership]
      end
    end

    factory :invoice_activity_log do
      activity_type 'invoices_sent'
      after :build do |activity_log, evaluator|
        activity_log.payloads = [FactoryGirl.create(:invoice, company: activity_log.company)]
      end
    end
  end
end
