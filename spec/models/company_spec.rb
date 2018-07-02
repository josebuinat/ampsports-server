require 'rails_helper'

describe Company do
  describe 'attributes' do
    let!(:admin) { create(:admin, :with_company) }
    let(:company) { admin.company }

    it 'should have a bank name attribute' do
      expect(company).to have_attributes(bank_name: 'Big good bank')
    end
  end

  describe 'currency' do
    context 'when is not set' do
      let(:company) { create :company, currency: nil }

      it 'should have dollar currency unit' do
        expect(company.currency_unit).to eql '$'
      end
    end

    context 'when is set to "usd"' do
      let(:company) { create :usd_company}

      it 'should have "$" as currency unit' do
        expect(company.currency_unit).to eql '$'
      end
    end
  end

  context 'scopes' do
    let!(:admin) { create(:admin, :with_company) }
    let!(:company) { admin.company }

    describe '#participations_by_biller' do
      subject { company.participations_by_biller(custom_biller) }

      let!(:venue) { create :venue, :with_courts, :with_users, user_count: 2, company: company }
      let!(:court1) { venue.courts.first }
      let!(:court2) { venue.courts.last }
      let!(:user1) { venue.users.first }
      let!(:user2) { venue.users.second }
      let!(:default_group) { create :group, venue: venue, owner: user1 }
      let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user2 }
      let!(:default_reservation) { create :reservation, user: default_group, court: court1 }
      let!(:custom_biller_reservation) { create :reservation, user: group_with_biller, court: court2 }
      let!(:default_participation) { create :participation, reservation: default_reservation, user: user1 }
      let!(:custom_biller_participation) { create :participation, reservation: custom_biller_reservation, user: user1 }

      context 'by default biller(company)' do
        let(:custom_biller) { nil }

        let!(:other_company_group) { create :group }
        let!(:other_company_reservation) {
          create :reservation, user: other_company_group, court: create(:court, venue: other_company_group.venue)
        }
        let!(:other_company_participation) { create :participation, reservation: other_company_reservation }

        it 'returns participations for groups without custom biller' do
          is_expected.to include(default_participation)
        end

        it 'does not return participations for group with custom biller' do
          is_expected.not_to include(custom_biller_participation)
        end

        it 'does not return participations for other company' do
          is_expected.not_to include(other_company_participation)
        end
      end

      context 'by custom biller' do
        let(:custom_biller) { group_with_biller.custom_biller }

        let!(:group_with_other_biller) { create :group, :with_custom_biller, venue: venue, owner: user2 }
        let!(:other_biller_reservation) {
          create :reservation, user: group_with_other_biller, court: court1,
                               start_time: default_reservation.start_time + 1.days
        }
        let!(:other_biller_participation) { create :participation, reservation: other_biller_reservation }

        it 'returns participations for group with specified custom biller' do
          is_expected.to include(custom_biller_participation)
        end

        it 'does not return participations for group with other custom biller' do
          is_expected.not_to include(other_biller_participation)
        end

        it 'does not return participations for group without custom biller' do
          is_expected.not_to include(default_participation)
        end
      end
    end

    describe '#group_subscriptions_by_biller' do
      subject { company.group_subscriptions_by_biller(custom_biller) }

      let!(:venue) { create :venue, :with_users, user_count: 2, company: company }
      let!(:user1) { venue.users.first }
      let!(:user2) { venue.users.second }

      let!(:default_group) { create :group, venue: venue, owner: user1, priced_duration: :season }
      let!(:group_with_biller) {
        create :group, :with_custom_biller, venue: venue, owner: user2, priced_duration: :season }
      let!(:default_group_season) { create :group_season, group: default_group }
      let!(:custom_biller_group_season) { create :group_season, group: group_with_biller }
      let!(:default_group_subscription) {
        create :group_subscription, group_season: default_group_season, user: user1 }
      let!(:custom_biller_group_subscription) {
        create :group_subscription, group_season: custom_biller_group_season, user: user1 }

      context 'by default biller(company)' do
        let(:custom_biller) { nil }

        let!(:other_company_group) { create :group, priced_duration: :season }
        let!(:other_company_group_season) { create :group_season, group: other_company_group }
        let!(:other_company_group_subscription) { create :group_subscription, group_season: other_company_group_season }

        it 'returns group_subscriptions for groups without custom biller' do
          is_expected.to include(default_group_subscription)
        end

        it 'does not return group_subscriptions for group with custom biller' do
          is_expected.not_to include(custom_biller_group_subscription)
        end

        it 'does not return group_subscriptions for other company' do
          is_expected.not_to include(other_company_group_subscription)
        end
      end

      context 'by custom biller' do
        let(:custom_biller) { group_with_biller.custom_biller }

        let!(:group_with_other_biller) {
          create :group, :with_custom_biller, venue: venue, owner: user2, priced_duration: :season }
        let!(:other_biller_group_season) { create :group_season, group: group_with_other_biller }
        let!(:other_biller_group_subscription) { create :group_subscription, group_season: other_biller_group_season }

        it 'returns group_subscriptions for group with specified custom biller' do
          is_expected.to include(custom_biller_group_subscription)
        end

        it 'does not return group_subscriptions for group with other custom biller' do
          is_expected.not_to include(other_biller_group_subscription)
        end

        it 'does not return group_subscriptions for group without custom biller' do
          is_expected.not_to include(default_group_subscription)
        end
      end
    end

    describe '#memberships_users' do
      let!(:venue) { create :venue, :with_courts, :with_users, user_count: 2, company: company }
      let!(:user1) { venue.users.first }
      let!(:user2) { venue.users.second }
      let!(:group) { create :group, venue: venue, owner: user2 }
      let!(:user_membership) { create :membership, venue: venue, user: user1 }
      let!(:group_membership) { create :membership, venue: venue, user: group }

      it 'returns membership owners through groups' do
        expect(company.memberships_users).to match_array([user1, user2])
      end
    end
  end

  context 'calculate outstanding balance' do
    let!(:admin) { create(:admin, :with_company) }
    let!(:company) { admin.company }
    let!(:venue) { create :venue, :with_courts, :with_users, user_count: 2, company: company }
    let!(:court1) { venue.courts.first }
    let!(:court2) { venue.courts.last }
    let!(:user) { venue.users.first }
    let!(:other_user) { venue.users.second }
    let(:custom_biller) { nil }

    describe '#user_outstanding_balance' do
      subject { company.user_outstanding_balance(user, custom_biller) }

      context 'user without anything' do
        it 'returns zero in decimal' do
          is_expected.to be_zero
          expect(subject).to be_kind_of BigDecimal
        end
      end

      context 'reservations' do
        it 'does not count paid and returns zero' do
          create :reservation, user: user, price: 7.0,  court: court1,
                               is_paid: true, payment_type: :paid,
                               billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
          expect(subject).to be_kind_of BigDecimal
        end

        it 'does not count paid with corrupted paid status(one part of is_paid or paid?)' do
          create :reservation, user: user, price: 39.0,  court: court1,
                                        is_paid: true, payment_type: :unpaid
          create :reservation, user: user, price: 43.0,  court: court2,
                                        is_paid: false, payment_type: :paid

          is_expected.to be_zero
        end

        it 'does not count invoiced' do
          create :reservation, user: user, price: 27.0,  court: court1,
                               billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
        end

        it 'counts unpaid part of semipaid' do
          create :reservation, user: user, price: 9.0,  court: court1,
                                      amount_paid: 4.0, payment_type: :semi_paid

          is_expected.to eq 5.to_d
        end

        it 'counts unpaid' do
          create :reservation, user: user, price: 11.0, court: court1

          is_expected.to eq 11.to_d
        end

        it 'does not count unpaid of other user' do
          create :reservation, user: other_user, price: 11.0, court: court1

          is_expected.to be_zero
        end

        context 'with custom_biller' do
          let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'does not count any reservations' do
            create :reservation, user: user, price: 11.0, court: court1

            is_expected.to be_zero
          end
        end
      end

      context 'game passes' do
        it 'does not count paid and returns zero' do
          create :game_pass, user: user, price: 13.0, venue: venue, is_paid: true

          is_expected.to be_zero
          expect(subject).to be_kind_of BigDecimal
        end

        it 'does not count invoiced' do
          create :game_pass, user: user, price: 13.0, venue: venue,
                             billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
        end

        it 'counts unpaid' do
          create :game_pass, user: user, price: 17.0, venue: venue

          is_expected.to eq 17.to_d
        end

        it 'does not count unpaid of other user' do
          create :game_pass, user: other_user, price: 17.0, venue: venue

          is_expected.to be_zero
        end

        context 'with custom_biller' do
          let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'does not count any game passes' do
            create :game_pass, user: user, price: 17.0, venue: venue

            is_expected.to be_zero
          end
        end
      end

      context 'participations' do
        let!(:group) { create :group, venue: venue, owner: user }
        let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
        let!(:reservation) { create :reservation, user: group, price: 0, court: court1 }
        let!(:reservation_with_biller) {
          create :reservation, user: group_with_biller, price: 0, court: court2 }

        it 'does not count paid' do
          create :participation, user: user, reservation: reservation, price: 87, is_paid: true

          is_expected.to be_zero
        end

        it 'does not count invoiced' do
          create :participation, user: user, reservation: reservation, price: 67,
                                  billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
        end

        it 'does not count unpaid  of other user' do
          create :participation, user: other_user, reservation: reservation, price: 17

          is_expected.to be_zero
        end

        context 'without custom_biller' do
          it 'counts unpaid for groups without custom biller' do
            create :participation, user: user, reservation: reservation, price: 17

            is_expected.to eq 17.to_d
          end

          it 'does not count unpaid for groups with custom billers' do
            create :participation, user: user, reservation: reservation_with_biller, price: 17

            is_expected.to be_zero
          end
        end

        context 'for custom_biller' do
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'counts unpaid for groups with custom biller' do
            create :participation, user: user, reservation: reservation_with_biller, price: 17

            is_expected.to eq 17.to_d
          end

          it 'does not count unpaid for groups without custom billers' do
            create :participation, user: user, reservation: reservation, price: 17

            is_expected.to be_zero
          end
        end
      end

      context 'group_subscriptions' do
        let!(:group) { create :group, venue: venue, owner: user, priced_duration: :season }
        let!(:group_with_biller) {
          create :group, :with_custom_biller, venue: venue, owner: user, priced_duration: :season }
        let!(:group_season) { create :group_season, group: group }
        let!(:group_season_with_biller) { create :group_season, group: group_with_biller }


        it 'does not count paid' do
          create :group_subscription, user: user, group_season: group_season, price: 89, is_paid: true

          is_expected.to be_zero
        end

        it 'does not count invoiced' do
          create :group_subscription, user: user, group_season: group_season, price: 69,
                                      billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
        end

        it 'does not count unpaid of other user' do
          create :group_subscription, user: other_user, group_season: group_season, price: 19

          is_expected.to be_zero
        end

        context 'without custom_biller' do
          it 'counts unpaid for groups without custom biller' do
            create :group_subscription, user: user, group_season: group_season, price: 19

            is_expected.to eq 19.to_d
          end

          it 'does not count unpaid for groups with custom billers' do
            create :group_subscription, user: user, group_season: group_season_with_biller, price: 19

            is_expected.to be_zero
          end
        end

        context 'for custom_biller' do
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'counts unpaid for groups with custom biller' do
            create :group_subscription, user: user, group_season: group_season_with_biller, price: 19

            is_expected.to eq 19.to_d
          end

          it 'does not count unpaid for groups without custom billers' do
            create :group_subscription, user: user, group_season: group_season, price: 19

            is_expected.to be_zero
          end
        end
      end
    end

    describe '#outstanding_balances' do
      subject { company.outstanding_balances }

      let!(:group) { create :group, venue: venue, owner: user, priced_duration: :season }
      let!(:group_season) { create :group_season, group: group }
      let!(:unpaid_group_reservation) { create :reservation, user: group, price: 1.0, court: court1 }
      let!(:unpaid_game_pass) { create :game_pass, user: user, price: 3.0, venue: venue }
      let!(:unpaid_participation) {
        create :participation, user: user, reservation: unpaid_group_reservation, price: 7 }
      let!(:unpaid_group_subscription) {
        create :group_subscription, user: user, group_season: group_season, price: 9 }
      let!(:unpaid_other_reservation) {
        create :reservation, user: other_user, price: 1.0, court: court2 }

      it 'returns outstanding balance for all users' do
        company.users.map do |user|
          expect(subject[user.id]).to eq company.user_outstanding_balance(user)
          expect(subject[user.id]).to be_kind_of BigDecimal
        end
      end
    end

    describe '#coach_outstanding_balance' do
      subject { company.coach_outstanding_balance(coach) }

      let!(:coach) { create :coach, :available, company: company, for_court: court1 }

      context 'coach without anything' do
        it 'returns zero in decimal' do
          is_expected.to be_zero
          expect(subject).to be_kind_of BigDecimal
        end
      end

      context 'reservations' do
        it 'does not count paid and returns zero' do
          create :reservation, user: coach, price: 7.0,  court: court1,
                               is_paid: true, payment_type: :paid,
                               billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
          expect(subject).to be_kind_of BigDecimal
        end

        it 'does not count invoiced' do
          create :reservation, user: coach, price: 27.0,  court: court1,
                               billing_phase: Reservation.billing_phases[:billed]

          is_expected.to be_zero
        end

        it 'counts unpaid part of semipaid' do
          create :reservation, user: coach, price: 9.0,  court: court1,
                                      amount_paid: 4.0, payment_type: :semi_paid

          is_expected.to eq 5.to_d
        end

        it 'counts unpaid' do
          create :reservation, user: coach, price: 11.0, court: court1

          is_expected.to eq 11.to_d
        end

        it 'does not count unpaid of other coach' do
          other_coach = create(:coach, :available, company: company, for_court: court1)

          create :reservation, user: other_coach, price: 11.0, court: court1

          is_expected.to be_zero
        end

        it 'does not count unpaid of other user' do
          create :reservation, user: other_user, price: 11.0, court: court1

          is_expected.to be_zero
        end
      end
    end

    describe '#coach_outstanding_balances' do
      subject { company.coach_outstanding_balances }
      let!(:coach) { create :coach, :available, company: company, for_court: court1 }
      let!(:other_coach) { create :coach, :available, company: company, for_court: court1 }

      let!(:unpaid_reservation) {
        create :reservation, user: coach, price: 7.0, court: court1
      }
      let!(:unpaid_other_reservation) {
        create :reservation, user: other_coach, price: 9.0, court: court2 }

      it 'returns outstanding balance for all coaches' do
        company.coaches.map do |coach|
          expect(subject[coach.id]).to eq company.coach_outstanding_balance(coach)
          expect(subject[coach.id]).to be_kind_of BigDecimal
        end
      end
    end
  end

  context 'calculate credit balance' do
    let!(:admin) { create(:admin, :with_company) }
    let!(:company) { admin.company }
    let!(:venue) { create :venue, :with_users, user_count: 3, company: company }
    let!(:user1) { venue.users.first }
    let!(:user2) { venue.users.second }
    let!(:user3) { venue.users.last }

    before do
      create :credit, company: company, user: user1, balance: 13
      create :credit, company: company, user: user1, balance: -7

      create :credit, company: company, user: user2, balance: -19
    end

    describe '#user_credit_balance' do
      it 'returns credit balance for user as decimal' do
        credit_balance = company.credits.where(user: user1).sum(:balance)
        calculated_balance = company.user_credit_balance(user1)

        expect(calculated_balance).to eq credit_balance
        expect(calculated_balance).to eq (13 - 7).to_d
        expect(calculated_balance).to be_kind_of BigDecimal
      end

      it 'returns negative credit balance for other user as decimal' do
        credit_balance = company.credits.where(user: user2).sum(:balance)
        calculated_balance = company.user_credit_balance(user2)

        expect(calculated_balance).to eq credit_balance
        expect(calculated_balance).to eq (-19).to_d
        expect(calculated_balance).to be_kind_of BigDecimal
      end

      it 'returns zero credit balance for user without balance' do
        calculated_balance = company.user_credit_balance(user3)

        expect(company.credits.where(user: user3).count).to be_zero
        expect(calculated_balance).to be_zero
        expect(calculated_balance).to be_kind_of BigDecimal
      end
    end

    describe '#credit_balances' do
      it 'returns credit balance for all users' do
        credit_balances = company.credit_balances

        company.users.map do |user|
          expect(credit_balances[user.id]).to eq company.user_credit_balance(user)
          expect(credit_balances[user.id]).to be_kind_of BigDecimal
        end
      end
    end
  end
end
