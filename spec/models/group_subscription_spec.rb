require 'rails_helper'

RSpec.describe GroupSubscription, type: :model do
  let!(:venue) { create :venue, :with_courts, :with_users, court_counts: 1 }
  let!(:user) { venue.users.first }
  let!(:court) { venue.courts.first }
  let!(:group) { create :group, venue: venue, priced_duration: :season }
  let!(:group_season) { create :group_season, group: group, current: true }
  let!(:group_subscription) { build :group_subscription, user: user, group_season: group_season }

  it 'can be created' do
    expect{group_subscription.save}.not_to raise_error
  end

  context 'validations' do
    describe "#user" do
      context "validate presence" do
        it "adds error when absent" do
          group_subscription.user = nil

          expect(group_subscription).not_to be_valid
          expect(group_subscription.errors).to include(:user)
        end

        it "is valid when present" do
          expect(group_subscription).to be_valid
        end
      end
    end

    describe "#group_season" do
      context "validate presence" do
        it "adds error when absent" do
          group_subscription.group_season = nil

          expect(group_subscription).not_to be_valid
          expect(group_subscription.errors).to include(:group_season)
        end

        it "is valid when present" do
          expect(group_subscription).to be_valid
        end
      end
    end

    describe "#price" do
      context "validate presence" do
        it "adds error when absent" do
          group.update_attribute(:participation_price, nil) # othervise it will set auto
          group_subscription.price = nil

          expect(group_subscription).not_to be_valid
          expect(group_subscription.errors).to include(:price)
        end

        it "is valid when present" do
          expect(group_subscription).to be_valid
        end
      end
    end
  end

  describe "#cancel" do
    let!(:group_subscription) { create :group_subscription, group_season: group_season }

    context 'cancels group_subscription' do
      subject{ group_subscription.cancel }

      it "updates cancelled to true" do
        expect{ subject }.to change{ GroupSubscription.active.count }.by(-1)
                         .and change{ GroupSubscription.cancelled.count }.by(1)
      end
    end

    context 'invoiced' do
      let!(:invoice) { Invoice.create_for_company(venue.company, group_subscription.user) }

      it 'deletes group_subscription invoice components' do
        expect(invoice.group_subscription_invoice_components.count).to eq 1
        expect(invoice.group_subscription_invoice_components.first.group_subscription).to eq group_subscription

        group_subscription.cancel
        invoice.reload

        expect(invoice.group_subscription_invoice_components.count).to eq 0
      end

      it 'recalculates invoice total' do
        expect(invoice.total).to eq group_subscription.price

        group_subscription.cancel
        invoice.reload

        expect(invoice.total).to eq 0
      end
    end
  end

  describe 'before_validation :set_price' do
    it 'sets group price' do
      expect{ group_subscription.save }
        .to change{ group_subscription.price }.from(nil).to(group.participation_price)
    end

    it 'sets season price' do
      group_season.update(participation_price: 6521)
      expect{ group_subscription.save }
        .to change{ group_subscription.price }.from(nil).to(group_season.participation_price)
    end

    it 'does not change already set price' do
      group_subscription.price = 52342

      expect{ group_subscription.save }
        .not_to change{ group_subscription.price }
    end
  end

  describe "#amount_paid" do
    subject { group_subscription.amount_paid }

    let(:group_subscription) {
      create :group_subscription, user: user,
                                  group_season: group_season,
                                  is_paid: is_paid,
                                  amount_paid: amount_paid
    }
    let(:is_paid) { true }
    let(:amount_paid) { nil }

    it 'returns full price' do
      expect(subject).to eq group_subscription.price
    end

    context 'unpaid subscription' do
      let(:is_paid) { false }

      it 'returns not nil zero amount' do
        expect(subject).not_to be_nil
        expect(subject).to be_zero
      end

      context 'patially paid' do
        let(:amount_paid) { 1 }

        it 'returns partial amount' do
          expect(subject).to eq amount_paid
        end
      end
    end
  end

  describe 'before_validation :set_is_paid' do
    let(:group_subscription) { create :group_subscription, user: user, group_season: group_season }

    it 'sets is paid status if paid amount covers price' do
      expect{ group_subscription.update(amount_paid: group_subscription.price) }
        .to change{ group_subscription.is_paid }.from(false).to(true)
    end

    it 'does not set is paid status if paid amount does not cover full price' do
      expect{ group_subscription.update(amount_paid: group_subscription.price - 1) }
        .not_to change{ group_subscription.is_paid }
    end
  end

  describe '#reservations' do
    subject { group_subscription.reservations }

    let!(:group_subscription) { create :group_subscription, user: user, group_season: group_season }

    context 'group reservation' do
      let!(:reservation) { create :reservation, user: group, court: court }
      let!(:other_group_reservation) { create :reservation, user: create(:group), court: court,
                                                    start_time: reservation.start_time + 1.days }

      it 'returns reservations of this group' do
        is_expected.to include(reservation)
      end

      it 'does not return reservations of different group' do
        is_expected.not_to include(other_group_reservation)
      end
    end

    context 'season' do
      let!(:reservation) { create :reservation, user: group, court: court, booking_type: :admin,
                                                start_time: start_time, end_time: end_time }
      let(:start_time_at_noon) { in_venue_tz { group_subscription.start_time.in_time_zone.at_noon } }
      let(:end_time_at_noon) { in_venue_tz { group_subscription.end_time.in_time_zone.at_noon } }

      context 'after start_date' do
        let(:start_time) { start_time_at_noon + 1.days }
        let(:end_time) { start_time + 1.hours }

        it 'returns reservation' do
          is_expected.to include(reservation)
        end
      end

      context 'before end_date' do
        let(:start_time) { end_time - 1.hours }
        let(:end_time) { end_time_at_noon - 1.days }

        it 'returns reservation' do
          is_expected.to include(reservation)
        end
      end

      context 'before start_date' do
        let(:start_time) { start_time_at_noon - 1.days }
        let(:end_time) { start_time + 1.hours }

        it 'does not return reservation' do
          is_expected.not_to include(reservation)
        end
      end

      context 'after end_date' do
        let(:start_time) { end_time - 1.hours }
        let(:end_time) { end_time_at_noon + 1.days }

        it 'does not return reservation' do
          is_expected.not_to include(reservation)
        end
      end
    end
  end

  describe 'after_save :mark_paid_participations, if: :was_paid?' do
    let!(:group_member) { create :group_member, group: group, user: user }
    let!(:group_subscription) { group_member.subscriptions.last }
    let!(:reservation) { create :reservation, user: group, court: court }
    let(:start_time) { in_venue_tz { group_subscription.end_time.in_time_zone.at_noon + 1.days } }
    let!(:other_season_reservation) { create :reservation, user: group,
                                                           court: court,
                                                           start_time: start_time }
    let!(:participation) { reservation.participations.last }
    let!(:other_season_participation) { other_season_reservation.participations.last }


    it 'updates participation for existing reservation as marks paid' do
      expect{ group_subscription.mark_paid }
        .to change{ participation.reload.is_paid }.from(false).to(true)
    end

    it 'does not update participation from other season subscription' do
      expect{ group_subscription.mark_paid }
        .not_to change{ other_season_participation.reload.is_paid }
    end

    it 'does not update participation if was not paid' do
      expect{ group_subscription.update(billing_phase: :billed) }
        .not_to change{ participation.reload.is_paid }
    end
  end

  describe '#mark_paid' do
    let(:group_subscription) { create :group_subscription, user: user, group_season: group_season }

    subject { group_subscription.mark_paid(amount) }
    let(:amount) { nil }

    context 'without amount' do
      it 'marks paid' do
        expect{ subject }
          .to change{ group_subscription.reload.is_paid }.from(false).to(true)
          .and change{ group_subscription.reload.amount_paid }.from(0.to_d)
                                                              .to(group_subscription.price)
      end
    end

    context 'with full amount' do
      let(:amount) { group_subscription.price }

      it 'marks paid' do
        expect{ subject }
          .to change{ group_subscription.reload.is_paid }.from(false).to(true)
          .and change{ group_subscription.reload.amount_paid }.from(0.to_d)
                                                              .to(group_subscription.price)
      end
    end

    context 'with partial amount' do
      let(:amount) { 1 }

      it 'updates amount but remain unpaid status' do
        expect{ subject }
          .to do_not_change{ group_subscription.reload.is_paid }
          .and change{ group_subscription.reload.amount_paid }.from(0.to_d).to(amount)
      end
    end
  end
end
