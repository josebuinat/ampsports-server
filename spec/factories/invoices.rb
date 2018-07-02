FactoryGirl.define do
  factory :invoice do
    due_time DateTime.tomorrow
    billing_time DateTime.current

    association :owner, factory: :user
    company

    reference_number FIViite.random(length: 10).paper_format

    trait :with_ics do
      transient do
        ic_count 2
      end

      after(:build) do |invoice, evaluator|
        components = InvoiceComponent.build_from(
          create_list(:reservation, evaluator.ic_count, user: invoice.owner)
        )
        invoice.invoice_components = components
      end
    end

    trait :with_cics do
      transient do
        cic_count 2
      end

      after(:build) do |invoice, evaluator|
        create_list(:custom_invoice_component, evaluator.cic_count, invoice: invoice)
      end
    end

    trait :with_gics do
      transient do
        gic_count 2
      end

      after(:build) do |invoice, evaluator|
        components = GamepassInvoiceComponent.build_from(
          create_list(:game_pass, evaluator.gic_count, user: invoice.owner)
        )
        invoice.gamepass_invoice_components = components
      end
    end

    trait :with_pics do
      transient do
        gic_count 2
      end

      after(:build) do |invoice, evaluator|
        components = ParticipationInvoiceComponent.build_from(
          create_list(:participation, evaluator.gic_count, user: invoice.owner)
        )
        invoice.participation_invoice_components = components
      end
    end

    trait :with_gsics do
      transient do
        gic_count 2
      end

      after(:build) do |invoice, evaluator|
        components = GroupSubscriptionInvoiceComponent.build_from(
          create_list(:group_subscription, evaluator.gic_count, user: invoice.owner)
        )
        invoice.group_subscription_invoice_components = components
      end
    end
  end
end
