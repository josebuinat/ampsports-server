require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe '#delete' do
    let!(:company) { create(:company) }
    let!(:venue) { create :venue, :with_users, :with_courts, court_count: 1, company: company }
    let!(:user) { venue.users.first }
    let!(:reservation) { create :reservation,
                                user: user,
                                court: venue.courts.first,
                                price: 17
    }

    context 'release invoiced credit balance' do
      let!(:credit) { create :credit, company: company, user: user, balance: 13 }
      let!(:invoice) { Invoice.create_for_company(company, user) }

      context 'draft' do
        it 'removes invoice with credit balance change' do
          invoice.destroy

          expect(CustomInvoiceComponent.count).to eq 0
          expect(Credit.count).to eq 1
          expect(company.user_credit_balance(user)).to eq 13
        end

        it 'removes custom invoice component with credit balance change' do
          invoice.custom_invoice_components.last.destroy

          expect(CustomInvoiceComponent.count).to eq 0
          expect(Credit.count).to eq 1
          expect(company.user_credit_balance(user)).to eq 13
        end
      end

      context 'unpaid' do
        before(:each) do
          # stub mailer
          allow(InvoiceMailer).to receive_message_chain(:invoice_email, :deliver_later!)
          allow(InvoiceMailer).to receive_message_chain(:undo_send_email, :deliver_later!)

          invoice.send!
          invoice.undo_send!
        end

        it 'removes invoice with credit balance change' do
          invoice.destroy

          expect(CustomInvoiceComponent.count).to eq 0
          expect(Credit.count).to eq 1
          expect(company.user_credit_balance(user)).to eq 13
        end

        it 'removes custom invoice component with credit balance change' do
          invoice.custom_invoice_components.last.destroy

          expect(CustomInvoiceComponent.count).to eq 0
          expect(Credit.count).to eq 1
          expect(company.user_credit_balance(user)).to eq 13
        end
      end
    end
  end

  describe '#self.create_for_company' do
    let!(:company) { create(:company) }
    let!(:venue) { create :venue, :with_users, :with_courts, court_count: 1, company: company }
    let!(:court) { venue.courts.first }
    let!(:user) { venue.users.first }
    let(:custom_biller) { nil }

    subject { Invoice.create_for_company(company, user) }

    context 'nothing to invoice' do
      it 'does not create invoice' do
        expect(subject).to eq nil
        expect(Invoice.count).to eq 0
      end
    end

    context 'create invoice' do
      let!(:reservation) { create :reservation, user: user, price: 1.0,  court: court }

      it 'creates invoice with company' do
        expect(subject.is_a?(Invoice)).to be_truthy
        expect(subject.company).to eq company
      end

      it 'creates invoice with user' do
        expect(subject.owner).to eq user
      end
    end

    context 'create invoice with custom_biller' do
      subject { Invoice.create_for_company(company, user, { custom_biller: custom_biller }) }

      let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
      let!(:reservation_with_biller) { create :reservation, :paid, user: group_with_biller, court: court }
      let!(:unpaid_participation) { create :participation, user: user, reservation: reservation_with_biller }

      let(:custom_biller) { group_with_biller.custom_biller }

      it 'creates invoice with group_custom_biller' do
        expect(subject.is_a?(Invoice)).to be_truthy
        expect(subject.reload.group_custom_biller).to eq custom_biller
      end
    end

    context 'normal reservatons' do
      subject { Invoice.create_for_company(company, user).invoice_components }

      let(:start_time) do
        in_venue_tz do
          Time.current.advance(weeks: 2).beginning_of_week.at_noon
        end
      end

      context 'reservation statuses' do
        context 'unpaid reservation' do
          let!(:unpaid_reservation) { create :reservation, user: user, price: 11.0, court: court }

          it 'adds unpaid reservation to invoice and set correct price' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq unpaid_reservation
            expect(subject.first.price).to eq unpaid_reservation.outstanding_balance
          end
        end

        context 'semipaid reservation' do
          let!(:semipaid_reservation) { create :reservation, user: user, price: 9.0,  court: court,
                                        amount_paid: 4, payment_type: :semi_paid }

          it 'adds semipaid reservation to invoice and set correct price' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq semipaid_reservation
            expect(subject.first.price).to eq semipaid_reservation.outstanding_balance
          end
        end

        context 'paid reservation' do
          let!(:unpaid_reservation) { create :reservation, user: user, price: 11.0, court: court, start_time: start_time }
          let!(:paid_reservation) {
            create :reservation, user: user, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 is_paid: true, payment_type: :paid,
                                 billing_phase: Reservation.billing_phases[:billed]
          }

          it 'does not add paid reservation to invoice' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq unpaid_reservation
          end
        end

        context 'billed reservation' do
          let!(:unpaid_reservation) { create :reservation, user: user, price: 11.0, court: court, start_time: start_time }
          let!(:billed_reservation) {
            create :reservation, user: user, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 billing_phase: Reservation.billing_phases[:billed]
          }

          it 'does not add billed reservation to invoice' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq unpaid_reservation
          end
        end

        context 'drafted reservation' do
          let!(:unpaid_reservation) { create :reservation, user: user, price: 11.0, court: court, start_time: start_time }
          let!(:drafted_reservation) {
            create :reservation, user: user, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 billing_phase: Reservation.billing_phases[:drafted]
          }

          it 'does not add drafted reservation to invoice' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq unpaid_reservation
          end
        end
      end

      context 'reservations between dates' do
        subject { Invoice.create_for_company(company, user, { from: from, to: to }).invoice_components }

        let!(:early_reservation) { create :reservation, user: user, price: 11.0, court: court, start_time: start_time }
        let!(:late_reservation) { create :reservation, user: user, price: 1.0,  court: court, start_time: start_time + 3.days }

        context 'all reservations within time restriction' do
          let(:from) { start_time }
          let(:to) { start_time + 3.days }

          it 'adds all reservations to invoice' do
            expect(subject.count).to eq 2
          end
        end

        context 'one reservation within time restriction' do
          let(:from) { start_time }
          let(:to) { start_time + 2.days }

          it 'adds early reservation to invoice' do
            expect(subject.count).to eq 1
            expect(subject.first.reservation).to eq early_reservation
          end
        end

        context 'none reservations within time restriction' do
          subject { Invoice.create_for_company(company, user, { from: from, to: to }) }

          let(:from) { start_time + 4.days }
          let(:to) { start_time + 8.days }

          it 'does not create invoice' do
            expect(subject).to eq nil
          end
        end
      end

      context 'invoice with custom_biller' do
        subject { Invoice.create_for_company(company, user, { custom_biller: custom_biller }) }

        let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
        let(:custom_biller) { group_with_biller.custom_biller }

        it 'does not add any reservations' do
          expect(subject).to eq nil
        end
      end
    end

    context 'group reservatons' do
      let!(:group) { create :group, venue: venue, owner: user }
      let!(:group_reservation) { create :reservation, user: group, price: 1.0,  court: court }

      it 'adds user owned group reservation to invoice' do
        expect(subject.invoice_components.count).to eq 1
        expect(subject.invoice_components.first.reservation).to eq group_reservation
      end
    end

    context 'game passes' do
      subject { Invoice.create_for_company(company, user).gamepass_invoice_components }

      let!(:unpaid_game_pass) { create :game_pass, user: user, venue: venue }

      context 'unpaid game pass' do
        it 'adds user game pass to invoice and set price' do
          expect(subject.count).to eq 1
          expect(subject.first.game_pass).to eq unpaid_game_pass
          expect(subject.first.game_pass.price).to eq unpaid_game_pass.price
        end
      end

      context 'paid game pass' do
        let!(:paid_game_pass) { create :game_pass, user: user, venue: venue, is_paid: true }

        it 'does not add paid game pass to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.game_pass).to eq unpaid_game_pass
        end
      end

      context 'billed game pass' do
        let!(:billed_game_pass) {
          create :game_pass, user: user, venue: venue,
                             billing_phase: GamePass.billing_phases[:billed]
        }

        it 'does not add billed game pass to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.game_pass).to eq unpaid_game_pass
        end
      end

      context 'drafted game pass' do
        let!(:drafted_game_pass) {
          create :game_pass, user: user, venue: venue,
                             billing_phase: GamePass.billing_phases[:drafted]
        }

        it 'does not add drafted game pass to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.game_pass).to eq unpaid_game_pass
        end
      end

      context 'invoice with custom_biller' do
        subject { Invoice.create_for_company(company, user, { custom_biller: custom_biller }) }

        let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
        let(:custom_biller) { group_with_biller.custom_biller }

        it 'does not add any reservations' do
          expect(subject).to eq nil
        end
      end
    end

    context 'participations' do
      subject { Invoice.create_for_company(company, user, { custom_biller: custom_biller }).
                        participation_invoice_components }

      let!(:group) { create :group, venue: venue }
      let!(:paid_group_reservation) { create :reservation, :paid, user: group, court: court }
      let!(:paid_group_reservation2) { create :reservation, :paid, user: group, court: court,
                                        start_time: paid_group_reservation.start_time.advance(hours: 2) }
      let!(:group_with_biller) { create :group, :with_custom_biller, venue: venue, owner: user }
      let!(:reservation_with_biller) {
        create :reservation, :paid, user: group_with_biller, court: court,
                                    start_time: paid_group_reservation.start_time + 1.days
      }
      let!(:unpaid_participation) { create :participation, user: user, reservation: paid_group_reservation }

      context 'unpaid participation' do
        it 'adds user participation to invoice and set price' do
          expect(subject.count).to eq 1
          expect(subject.first.participation).to eq unpaid_participation
          expect(subject.first.participation.price).to eq unpaid_participation.price
        end
      end

      context 'paid participation' do
        let!(:paid_participation) { create :participation, user: user,
                                      reservation: paid_group_reservation2, is_paid: true }

        it 'does not add paid participation to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.participation).to eq unpaid_participation
        end
      end

      context 'billed participation' do
        let!(:billed_participation) {
          create :participation, user: user, reservation: paid_group_reservation2,
                             billing_phase: Participation.billing_phases[:billed]
        }

        it 'does not add billed participation to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.participation).to eq unpaid_participation
        end
      end

      context 'drafted participation' do
        let!(:drafted_participation) {
          create :participation, user: user, reservation: paid_group_reservation2,
                             billing_phase: Participation.billing_phases[:drafted]
        }

        it 'does not add drafted participation to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.participation).to eq unpaid_participation
        end
      end

      context 'participation with custom_biller' do
        let!(:unpaid_participation_with_biller) {
          create :participation, user: user, reservation: reservation_with_biller, price: 17
        }

        it 'adds only for groups without custom biller' do
          expect(subject.count).to eq 1
          expect(subject.first.participation).to eq unpaid_participation
        end

        context 'invoice with custom_biller' do
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'adds only for groups with specified custom biller' do
            expect(subject.count).to eq 1
            expect(subject.first.participation).to eq unpaid_participation_with_biller
          end
        end
      end
    end

    context 'group_subscriptions' do
      subject { Invoice.create_for_company(company, user, { custom_biller: custom_biller }).
                        group_subscription_invoice_components }

      let!(:group) { create :group, venue: venue, priced_duration: :season }
      let!(:group_season) { create :group_season, group: group }
      let!(:group_with_biller) {
        create :group, :with_custom_biller, venue: venue, owner: user, priced_duration: :season }
      let!(:group_season_with_biller) { create :group_season, group: group_with_biller }
      let!(:unpaid_group_subscription) { create :group_subscription, user: user, group_season: group_season }

      context 'unpaid group_subscription' do
        it 'adds user group_subscription to invoice and set price' do
          expect(subject.count).to eq 1
          expect(subject.first.group_subscription).to eq unpaid_group_subscription
          expect(subject.first.group_subscription.price).to eq unpaid_group_subscription.price
        end
      end

      context 'paid group_subscription' do
        let!(:paid_group_subscription) { create :group_subscription, user: user, group_season: group_season, is_paid: true }

        it 'does not add paid group_subscription to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.group_subscription).to eq unpaid_group_subscription
        end
      end

      context 'billed group_subscription' do
        let!(:billed_group_subscription) {
          create :group_subscription, user: user, group_season: group_season,
                             billing_phase: GroupSubscription.billing_phases[:billed]
        }

        it 'does not add billed group_subscription to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.group_subscription).to eq unpaid_group_subscription
        end
      end

      context 'drafted group_subscription' do
        let!(:drafted_group_subscription) {
          create :group_subscription, user: user, group_season: group_season,
                             billing_phase: GroupSubscription.billing_phases[:drafted]
        }

        it 'does not add drafted group_subscription to invoice' do
          expect(subject.count).to eq 1
          expect(subject.first.group_subscription).to eq unpaid_group_subscription
        end
      end

      context 'group_subscription with custom_biller' do
        let!(:unpaid_group_subscription_with_biller) {
          create :group_subscription, user: user, group_season: group_season_with_biller
        }

        it 'adds only for groups without custom biller' do
          expect(subject.count).to eq 1
          expect(subject.first.group_subscription).to eq unpaid_group_subscription
        end

        context 'invoice with custom_biller' do
          let(:custom_biller) { group_with_biller.custom_biller }

          it 'adds only for groups with specified custom biller' do
            expect(subject.count).to eq 1
            expect(subject.first.group_subscription).to eq unpaid_group_subscription_with_biller
          end
        end
      end
    end

    context 'default venue fee' do
      let!(:reservation) { create :reservation, user: user, price: 1.0,  court: court }

      before(:each) do
        venue.update_attribute(:invoice_fee, 18)
      end

      it 'adds venue invoice fee' do
        expect(subject.custom_invoice_components.count).to eq 1

        custom_component = subject.custom_invoice_components.first

        expect(custom_component.price).to eq 18
        expect(custom_component.name).to eq I18n.t('helpers.label.venue.invoice_fee')
        expect(custom_component.vat_decimal).to eq BigDecimal.new('0.24')
      end
    end

    context 'credit balance' do
      let!(:reservation) { create :reservation, user: user, court: court, price: 17 }

      context 'zero credit balance' do
        before(:each) do
          create :credit, company: company, user: user, balance: 13
          create :credit, company: company, user: user, balance: -13
        end

        it 'adds nothing' do
          expect(subject.custom_invoice_components.count).to eq 0
          expect(Credit.count).to eq 2
        end
      end

      context 'positive credit balance(discount) lesser than invoice total' do
        let!(:credit) { create :credit, company: company, user: user, balance: 13 }
        let!(:invoice) { subject }

        it 'creates discount custom invoice component' do
          expect(subject.custom_invoice_components.count).to eq 1

          custom_component = invoice.custom_invoice_components.last

          expect(custom_component.name).to eq I18n.t("invoices.custom_invoice_components.credit_discount")
          expect(custom_component.price).to eq (-credit.balance)
          expect(custom_component.vat_decimal).to eq company.tax_rate
        end

        it 'creates new credit balance for user and company' do
          expect(Credit.count).to eq 2

          new_credit = Credit.last

          expect(new_credit.id).not_to eq credit.id
          expect(new_credit.company).to eq company
          expect(new_credit.user).to eq user
          expect(new_credit.creditable).to eq invoice.custom_invoice_components.last
        end

        it 'decreases walet balance' do
          new_credit = Credit.last

          expect(new_credit.balance).to eq (-credit.balance)
          expect(company.user_credit_balance(user)).to eq 0
        end

        it 'recalculates invoice total' do
          expect(invoice.total).to eq (reservation.price - credit.balance)
          expect(invoice.total).to eq (17 - 13)
        end
      end

      context 'positive credit balance(discount) bigger than invoice total' do
        let!(:credit) { create :credit, company: company, user: user, balance: 27 }
        let!(:invoice) { subject }

        it 'creates discount custom invoice component' do
          expect(invoice.custom_invoice_components.count).to eq 1

          custom_component = invoice.custom_invoice_components.last

          expect(custom_component.name).to eq I18n.t("invoices.custom_invoice_components.credit_discount")
          expect(custom_component.price).to eq (-reservation.price)
          expect(custom_component.vat_decimal).to eq company.tax_rate
        end

        it 'creates new credit balance for user and company' do
          expect(Credit.count).to eq 2

          new_credit = Credit.last

          expect(new_credit.id).not_to eq credit.id
          expect(new_credit.company).to eq company
          expect(new_credit.user).to eq user
          expect(new_credit.creditable).to eq invoice.custom_invoice_components.last
        end

        it 'decreases walet balance by amount of total' do
          expect(Credit.count).to eq 2

          new_credit = Credit.last

          expect(new_credit.balance).to eq (-reservation.price)
          expect(company.user_credit_balance(user)).to eq (27 - 17)
        end

        it 'recalculates invoice total' do
          expect(invoice.total).to eq ( reservation.price - reservation.price )
          expect(invoice.total).to eq 0
        end
      end

      context 'negative credit balance(credit)' do
        let!(:credit) { create :credit, company: company, user: user, balance: -27 }
        let!(:invoice) { subject }

        it 'creates credit custom invoice component' do
          expect(invoice.custom_invoice_components.count).to eq 1

          custom_component = invoice.custom_invoice_components.last

          expect(custom_component.name).to eq I18n.t("invoices.custom_invoice_components.credit_addition")
          expect(custom_component.price).to eq (-credit.balance)
          expect(custom_component.vat_decimal).to eq company.tax_rate
        end

        it 'creates new credit balance for user and company' do
          expect(Credit.count).to eq 2

          new_credit = Credit.last

          expect(new_credit.id).not_to eq credit.id
          expect(new_credit.company).to eq company
          expect(new_credit.user).to eq user
          expect(new_credit.creditable).to eq invoice.custom_invoice_components.last
        end

        it 'increases walet balance' do
          new_credit = Credit.last

          expect(new_credit.balance).to eq (-credit.balance)
          expect(new_credit.balance).to eq 27
          expect(company.user_credit_balance(user)).to eq 0
        end

        it 'recalculates invoice total' do
          expect(invoice.total).to eq (reservation.price - credit.balance)
          expect(invoice.total).to eq (17 + 27)
        end
      end
    end

    context 'reference number' do
      let!(:reservation) { create :reservation, user: user, price: 1.0,  court: court }

      it 'sets reference number' do
        expect(subject.reference_number.present?).to be_truthy
      end
    end

    context 'calculate total' do
      let!(:reservation) do
        in_venue_tz do
          create :reservation, user: user, price: 11.0,  court: court
        end
      end
      let!(:game_pass) { create :game_pass, user: user, venue: venue, price: 13.0 }
      let!(:credit) { create :credit, company: company, user: user, balance: 27 }
      let!(:group) { create :group, venue: venue }
      let!(:paid_group_reservation) {
        create :reservation, :paid, user: group, court: court, start_time: reservation.start_time + 1.days
      }
      let!(:participation) { create :participation, user: user, reservation: paid_group_reservation }

      before(:each) do
        venue.update_attribute(:invoice_fee, 18)
      end

      it 'calculates correct total' do
        expect(subject.total).to eq (
          reservation.outstanding_balance +
          game_pass.price +
          venue.invoice_fee +
          (credit.balance * -1) +
          paid_group_reservation.participation_price)
      end
    end
  end

  describe '#self.create_for_coach' do
    let!(:company) { create(:company) }
    let!(:venue) { create :venue, :with_courts, court_count: 1, company: company }
    let!(:court) { venue.courts.first }
    let!(:user) { venue.users.first }
    let(:coach) { create :coach, :available, company: company, for_court: court }

    subject { Invoice.create_for_coach(coach) }

    context 'nothing to invoice' do
      it 'does not create invoice' do
        expect{ subject }.not_to change{ Invoice.count }
      end
    end

    context 'create invoice' do
      let!(:reservation) { create :reservation, user: coach, price: 1.0,  court: court }

      it 'creates invoice for a coach and company' do
        expect{ subject }.to change{ company.invoices.count }.by(1)
        expect(subject.owner).to eq coach
      end
    end

    context 'normal reservatons' do
      let(:new_component) { subject.invoice_components.first }

      let(:start_time) do
        in_venue_tz do
          Time.current.advance(weeks: 2).beginning_of_week.at_noon
        end
      end

      context 'reservation statuses' do
        context 'unpaid reservation' do
          let!(:unpaid_reservation) { create :reservation, user: coach, price: 11.0, court: court }

          it 'adds unpaid reservation to invoice and set correct price' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq unpaid_reservation
            expect(new_component.price).to eq unpaid_reservation.outstanding_balance
          end
        end

        context 'semipaid reservation' do
          let!(:semipaid_reservation) { create :reservation, user: coach, price: 9.0,  court: court,
                                        amount_paid: 4, payment_type: :semi_paid }

          it 'adds semipaid reservation to invoice and set correct price' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq semipaid_reservation
            expect(new_component.price).to eq semipaid_reservation.outstanding_balance
          end
        end

        context 'paid reservation' do
          let!(:unpaid_reservation) { create :reservation, user: coach, price: 11.0, court: court, start_time: start_time }
          let!(:paid_reservation) {
            create :reservation, user: coach, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 is_paid: true, payment_type: :paid,
                                 billing_phase: Reservation.billing_phases[:billed]
          }

          it 'does not add paid reservation to invoice' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq unpaid_reservation
          end
        end

        context 'billed reservation' do
          let!(:unpaid_reservation) { create :reservation, user: coach, price: 11.0, court: court, start_time: start_time }
          let!(:billed_reservation) {
            create :reservation, user: coach, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 billing_phase: Reservation.billing_phases[:billed]
          }

          it 'does not add billed reservation to invoice' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq unpaid_reservation
          end
        end

        context 'drafted reservation' do
          let!(:unpaid_reservation) { create :reservation, user: coach, price: 11.0, court: court, start_time: start_time }
          let!(:drafted_reservation) {
            create :reservation, user: coach, price: 7.0,  court: court, start_time: start_time + 1.days,
                                 billing_phase: Reservation.billing_phases[:drafted]
          }

          it 'does not add drafted reservation to invoice' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq unpaid_reservation
          end
        end
      end

      context 'reservations between dates' do
        subject { Invoice.create_for_coach(coach, { from: from, to: to }) }

        let!(:early_reservation) { create :reservation, user: coach, price: 11.0, court: court, start_time: start_time }
        let!(:late_reservation) { create :reservation, user: coach, price: 1.0,  court: court, start_time: start_time + 3.days }

        context 'all reservations within time restriction' do
          let(:from) { start_time }
          let(:to) { start_time + 3.days }

          it 'adds all reservations to invoice' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(2)
          end
        end

        context 'one reservation within time restriction' do
          let(:from) { start_time }
          let(:to) { start_time + 2.days }

          it 'adds early reservation to invoice' do
            expect{ subject }.to change{ InvoiceComponent.count }.by(1)
            expect(new_component.reservation).to eq early_reservation
          end
        end

        context 'none reservations within time restriction' do
          let(:from) { start_time + 4.days }
          let(:to) { start_time + 8.days }

          it 'does not create invoice' do
            expect{ subject }.not_to change{ InvoiceComponent.count }
          end
        end
      end
    end
  end

  describe '#send!' do
    let!(:venue) { create :venue, :with_users, :with_courts, user_count: 2, court_count: 1 }
    let!(:user1) { venue.users.first }
    let!(:user2) { venue.users.second }
    let!(:invoice_draft) { create :invoice, owner: user1, company: venue.company, is_draft: true }

    context 'attributes of self' do
      let!(:reservation) { create :reservation, user: user1, court: venue.courts.first }

      before(:each) do
        # freeze current time
        allow(Time).to receive(:current).and_return(Time.current.at_noon)
        invoice_draft.update(invoice_components: InvoiceComponent.build_from([reservation]))
      end

      it 'sets is_draft to false' do
        invoice_draft.send!

        expect(invoice_draft.is_draft).to be_falsey
      end

      it 'sets current time for billing_time' do
        invoice_draft.send!

        expect(invoice_draft.billing_time).to eq Time.current
      end

      it 'sets custom due date if valid' do
        date = Date.current + 13.days
        invoice_draft.send!(date.to_s(:date))

        expect(invoice_draft.due_date).to eq date
      end

      it 'sets default(2 weeks ahead) due date if invalid' do
        invoice_draft.send!('invalid date')

        expect(invoice_draft.due_time).to eq Time.current.advance(weeks: 2)
        expect(invoice_draft.due_date).to eq (Date.current + 14.days)
      end

      it 'sets default(2 weeks ahead) due date if in the past' do
        date = Date.current - 1.days
        invoice_draft.send!(date.to_s(:date))

        expect(invoice_draft.due_time).to eq Time.current.advance(weeks: 2)
        expect(invoice_draft.due_date).to eq (Date.current + 14.days)
      end
    end

    context 'normal reservation' do
      let!(:reservation) { create :reservation, user: user1, court: venue.courts.first }

      before(:each) do
        invoice_draft.update(invoice_components: InvoiceComponent.build_from([reservation]))
      end

      it 'sets is_billed to true for invoice components' do
        invoice_draft.send!

        invoice_component = invoice_draft.invoice_components.reload.first

        expect(invoice_component.is_billed).to be_truthy
      end

      it 'sets billing_phase to billed for reservation' do
        invoice_draft.send!

        reservation.reload

        expect(reservation.billing_phase).to eq 'billed'
        expect(reservation.updated_at).not_to eq reservation.created_at
      end
    end

    context 'resold reservation' do
      let!(:reservation) { create :reservation,
                             user: invoice_draft.owner,
                             court: venue.courts.first,
                             reselling: true
      }

      before(:each) do
        # invoice created with reselling but still owned reservation
        invoice_draft.update(invoice_components: InvoiceComponent.build_from([reservation]))
        # sell to other user
        reservation.update_attribute(:user_id, user2.id)
      end

      it 'sets is_billed to true for invoice components' do
        invoice_draft.send!

        invoice_component = invoice_draft.invoice_components.reload.first

        expect(invoice_component.is_billed).to be_truthy
      end

      it 'does not touch resold reservation itself' do
        expect{ invoice_draft.send! }.to do_not_change{ reservation.reload.billing_phase }
                                     .and do_not_change{ reservation.reload.updated_at }
        expect(reservation.billing_phase).to eq 'drafted'
      end
    end

    context 'game pass' do
      let!(:game_pass) { create :game_pass, user: user1, venue: venue }

      before(:each) do
        invoice_draft.update(gamepass_invoice_components: GamepassInvoiceComponent.build_from([game_pass]))
      end

      it 'sets is_billed to true for gamepass invoice components' do
        invoice_draft.send!

        gamepass_invoice_component = invoice_draft.gamepass_invoice_components.reload.first

        expect(gamepass_invoice_component.is_billed).to be_truthy
      end

      it 'sets is_billed to true for game_pass' do
        invoice_draft.send!

        game_pass.reload

        expect(game_pass.billing_phase).to eq 'billed'
        expect(game_pass.updated_at).not_to eq game_pass.created_at
      end
    end

    context 'participation' do
      let!(:group) { create :group, venue: venue }
      let!(:paid_group_reservation) { create :reservation, :paid, user: group, court: venue.courts.first }
      let!(:participation) {
        create :participation, user: user1, reservation: paid_group_reservation,
                           billing_phase: Participation.billing_phases[:drafted]
      }

      before(:each) do
        invoice_draft.update(participation_invoice_components: ParticipationInvoiceComponent.build_from([participation]))
      end

      it 'sets is_billed to true for participation invoice components' do
        invoice_draft.send!

        participation_invoice_component = invoice_draft.participation_invoice_components.reload.first

        expect(participation_invoice_component.is_billed).to be_truthy
      end

      it 'sets is_billed to true for participation' do
        invoice_draft.send!

        participation.reload

        expect(participation.billing_phase).to eq 'billed'
        expect(participation.updated_at).not_to eq participation.created_at
      end
    end

    context 'group_subscription' do
      let!(:group) { create :group, venue: venue, priced_duration: :season }
      let!(:group_season) { create :group_season, group: group }
      let!(:group_subscription) {
        create :group_subscription, user: user1, group_season: group_season,
                           billing_phase: GroupSubscription.billing_phases[:drafted]
      }

      before(:each) do
        invoice_draft.update(group_subscription_invoice_components: GroupSubscriptionInvoiceComponent.build_from([group_subscription]))
      end

      it 'sets is_billed to true for group_subscription invoice components' do
        invoice_draft.send!

        group_subscription_invoice_component = invoice_draft.group_subscription_invoice_components.reload.first

        expect(group_subscription_invoice_component.is_billed).to be_truthy
      end

      it 'sets is_billed to true for group_subscription' do
        invoice_draft.send!

        group_subscription.reload

        expect(group_subscription.billing_phase).to eq 'billed'
        expect(group_subscription.updated_at).not_to eq group_subscription.created_at
      end
    end

    context 'custom component' do
      before(:each) do
        invoice_draft.custom_invoice_components.create(
          name: 'custom',
          price: 11,
          vat_decimal: BigDecimal.new('0.24'),
        )
      end

      it 'sets is_billed to true for custom invoice components' do
        invoice_draft.send!

        custom_invoice_component = invoice_draft.custom_invoice_components.reload.first

        expect(custom_invoice_component.is_billed).to be_truthy
      end
    end
  end

  describe '#mark_paid' do
    let!(:venue) { create :venue, :with_users, :with_courts, user_count: 2, court_count: 1 }
    let!(:user1) { venue.users.first }
    let!(:user2) { venue.users.second }
    let!(:group) { create :group, venue: venue, priced_duration: :season }
    let!(:group_season) { create :group_season, group: group }
    let!(:reservation) do
      in_venue_tz do
         create :reservation, user: user1, court: venue.courts.first,
                              billing_phase: Reservation.billing_phases[:billed]
      end
    end
    let!(:game_pass) { create :game_pass, user: user1, venue: venue,
                                  billing_phase: GamePass.billing_phases[:billed] }
    let!(:paid_group_reservation) { create :reservation, :paid, user: group, court: venue.courts.first,
                                                                start_time: reservation.start_time + 1.days }
    let!(:participation) { create :participation, user: user1, reservation: paid_group_reservation,
                                    billing_phase: Participation.billing_phases[:billed] }
    let!(:group_subscription) { create :group_subscription, user: user1, group_season: group_season,
                                    billing_phase: GroupSubscription.billing_phases[:billed] }
    let!(:custom_invoice_component) do
      CustomInvoiceComponent.new(
        name: 'custom',
        price: 11,
        vat_decimal: BigDecimal.new('0.24'),
      )
    end

    let!(:unpaid_invoice) {
      create :invoice,
        owner: user1,
        company: venue.company,
        is_draft: false,
        billing_time: Time.current,
        invoice_components: InvoiceComponent.build_from([reservation]),
        gamepass_invoice_components: GamepassInvoiceComponent.build_from([game_pass]),
        participation_invoice_components: ParticipationInvoiceComponent.build_from([participation]),
        group_subscription_invoice_components: GroupSubscriptionInvoiceComponent.build_from([group_subscription]),
        custom_invoice_components: [custom_invoice_component]
    }

    before(:each) do
      unpaid_invoice.reload
    end

    context 'attributes of self' do
      it 'sets is_paid to true' do
        unpaid_invoice.mark_paid

        expect(unpaid_invoice.is_paid).to be_truthy
      end
    end

    context 'normal reservation' do
      it 'sets is_paid to true for invoice components' do
        unpaid_invoice.mark_paid

        invoice_component = unpaid_invoice.invoice_components.reload.first

        expect(invoice_component.is_paid).to be_truthy
      end

      it 'sets is_paid to true for reservation' do
        unpaid_invoice.mark_paid

        reservation.reload

        expect(reservation.is_paid).to be_truthy
        expect(reservation.updated_at).not_to eq reservation.created_at
      end

      it 'sets amount_paid to price for reservation' do
        unpaid_invoice.mark_paid

        reservation.reload

        expect(reservation.amount_paid).to eq reservation.price
      end

      it 'sets payment_type to paid for reservation' do
        unpaid_invoice.mark_paid

        reservation.reload

        expect(reservation.payment_type).to eq 'paid'
      end
    end

    context 'resold reservation' do
      before(:each) do
        in_venue_tz do # to pass validations business hour validations
          reservation.update_attribute(:initial_membership_id, 1)
          reservation.update_attribute(:user, user2)
        end
      end

      it 'sets is_paid to true for invoice components' do
        unpaid_invoice.mark_paid

        invoice_component = unpaid_invoice.invoice_components.reload.first

        expect(invoice_component.is_paid).to be_truthy
      end

      it 'does not update reservation' do
        before_updated_at = reservation.reload.updated_at

        unpaid_invoice.mark_paid

        reservation.reload

        expect(reservation.is_paid).to be_falsey
        expect(reservation.updated_at).to eq before_updated_at
      end
    end

    context 'game pass' do
      it 'sets is_paid to true for gamepass invoice components' do
        unpaid_invoice.mark_paid

        gamepass_invoice_component = unpaid_invoice.gamepass_invoice_components.reload.first

        expect(gamepass_invoice_component.is_paid).to be_truthy
      end

      it 'sets is_paid to true for game_pass' do
        unpaid_invoice.mark_paid

        game_pass.reload

        expect(game_pass.is_paid).to be_truthy
        expect(game_pass.updated_at).not_to eq game_pass.created_at
      end
    end

    context 'participation' do
      it 'sets is_paid to true for participation invoice components' do
        unpaid_invoice.mark_paid

        participation_invoice_component = unpaid_invoice.participation_invoice_components.reload.first

        expect(participation_invoice_component.is_paid).to be_truthy
      end

      it 'sets is_paid to true for participation' do
        unpaid_invoice.mark_paid

        participation.reload

        expect(participation.is_paid).to be_truthy
        expect(participation.updated_at).not_to eq participation.created_at
      end
    end

    context 'group_subscription' do
      it 'sets is_paid to true for group_subscription invoice components' do
        unpaid_invoice.mark_paid

        group_subscription_invoice_component = unpaid_invoice.group_subscription_invoice_components.reload.first

        expect(group_subscription_invoice_component.is_paid).to be_truthy
      end

      it 'sets is_paid to true for group_subscription' do
        unpaid_invoice.mark_paid

        group_subscription.reload

        expect(group_subscription.is_paid).to be_truthy
        expect(group_subscription.updated_at).not_to eq group_subscription.created_at
      end
    end

    context 'custom component' do
      it 'sets is_paid to true for custom invoice components' do
        unpaid_invoice.mark_paid

        custom_invoice_component = unpaid_invoice.custom_invoice_components.reload.first

        expect(custom_invoice_component.is_paid).to be_truthy
      end
    end
  end

  context 'undrafting and deletion' do
    let!(:admin) { create(:admin, :with_company) }
    let!(:company) { admin.company }
    let!(:venue) { create :venue, :with_courts, :with_users, company: company }
    let!(:court1) { venue.courts.first }
    let!(:court2) { venue.courts.last }
    let!(:user) { venue.users.first }
    let(:start_time) do
      in_venue_tz do
        Time.current.advance(weeks: 2).beginning_of_week.at_noon
      end
    end
    let!(:group) { create :group, venue: venue, participation_price: 19, priced_duration: :season }
    let!(:group_season) { create :group_season, group: group }
    let!(:paid_group_reservation) {
      create :reservation, user: group, court: court1, start_time: start_time + 1.days,
                           is_paid: true, payment_type: :paid,
                           billing_phase: Reservation.billing_phases[:billed]
    }

    before(:each) do
      create :reservation, user: user, price: 11.0, court: court1, start_time: start_time
      create :reservation, user: user, price: 13.0, court: court2, start_time: start_time
      create :game_pass, user: user, venue: venue, price: 17.0
      create :participation, user: user, reservation: paid_group_reservation
      create :group_subscription, user: user, group_season: group_season, price: 333
    end

    let(:outstanding_balance) { 11 + 13 + 17 + 19 + 333 }

    describe '#destory' do
      context 'unpaid invoices' do
        it 'should return invoice compoents to invoiceable status' do
          expect(company.reload.outstanding_balances[user.id]).to eq outstanding_balance

          invoice = Invoice.create_for_company(company, user)
          invoice.send!((start_time + 3.months).to_s)
          user.reload

          expect(company.outstanding_balances[user.id]).to eq(0)
          expect(user.reservations.invoiceable.count).to eq(0)
          expect(user.game_passes.invoiceable.count).to eq(0)
          expect(user.participations.invoiceable.count).to eq(0)
          expect(user.group_subscriptions.invoiceable.count).to eq(0)
          expect(user.reservations.first.billing_phase).to eq('billed')
          expect(user.game_passes.first.billing_phase).to eq('billed')
          expect(user.participations.first.billing_phase).to eq('billed')
          expect(user.group_subscriptions.first.billing_phase).to eq('billed')

          invoice.destroy
          user.reload

          expect(company.reload.outstanding_balances[user.id]).to eq outstanding_balance
          expect(user.reservations.invoiceable.count).to eq(user.reservations.count)
          expect(user.game_passes.invoiceable.count).to eq(user.game_passes.count)
          expect(user.participations.invoiceable.count).to eq(user.participations.count)
          expect(user.reservations.first.billing_phase).to eq('not_billed')
          expect(user.game_passes.first.billing_phase).to eq('not_billed')
          expect(user.participations.first.billing_phase).to eq('not_billed')
          expect(user.group_subscriptions.first.billing_phase).to eq('not_billed')
        end
      end
    end

    describe '#undo send' do
      context 'unpaid invoices' do
        it 'should return invoice compoents to invoiceable status' do
          expect(company.reload.outstanding_balances[user.id]).to eq outstanding_balance

          invoice = Invoice.create_for_company(company, user)
          invoice.send!((start_time + 3.months).to_s)
          user.reload

          expect(company.outstanding_balances[user.id]).to eq(0)
          expect(user.reservations.invoiceable.count).to eq(0)
          expect(user.game_passes.invoiceable.count).to eq(0)
          expect(user.participations.invoiceable.count).to eq(0)
          expect(user.group_subscriptions.invoiceable.count).to eq(0)
          expect(user.reservations.first.billing_phase).to eq('billed')
          expect(user.game_passes.first.billing_phase).to eq('billed')
          expect(user.participations.first.billing_phase).to eq('billed')
          expect(user.group_subscriptions.first.billing_phase).to eq('billed')

          invoice.undo_send!
          user.reload

          expect(company.outstanding_balances[user.id]).to eq(0)
          expect(user.reservations.drafted.count).to eq(user.reservations.count)
          expect(user.game_passes.drafted.count).to eq(user.game_passes.count)
          expect(user.participations.drafted.count).to eq(user.participations.count)
          expect(user.group_subscriptions.drafted.count).to eq(user.group_subscriptions.count)
          expect(user.reservations.first.billing_phase).to eq('drafted')
          expect(user.game_passes.first.billing_phase).to eq('drafted')
          expect(user.participations.first.billing_phase).to eq('drafted')
          expect(user.group_subscriptions.first.billing_phase).to eq('drafted')
        end
      end
    end
  end
end
