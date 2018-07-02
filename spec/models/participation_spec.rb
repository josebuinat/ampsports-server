require 'rails_helper'

RSpec.describe Participation, type: :model do
  let!(:venue) { create :venue, :with_courts, :with_users, court_counts: 1 }
  let!(:user) { venue.users.first }
  let!(:group) { create :group, venue: venue }
  let!(:reservation) { create :reservation, user: group, court: venue.courts.first }

  it 'can be created' do
    expect{create :participation, reservation: reservation}.not_to raise_error
  end

  context 'validations' do
    let!(:participation) { build :participation, reservation: reservation, user: user }

    describe "#user" do
      context "validate presence" do
        it "adds error when absent" do
          participation.user = nil

          expect(participation).not_to be_valid
          expect(participation.errors).to include(:user)
        end

        it "is valid when present" do
          expect(participation).to be_valid
        end
      end

      context 'when user already participating' do
        context 'when active participation' do
          let!(:existing_participation) {
            create :participation, reservation: reservation, user: user
          }

          it "adds error" do
            error = I18n.t('activerecord.errors.models.participation.attributes.reservation.already_participating')

            expect(participation).not_to be_valid
            expect(participation.errors).to include(:reservation)
            expect(participation.errors.messages[:reservation]).to include(error)
          end
        end

        context 'when cancelled participation' do
          let!(:existing_cancelled_participation) {
            create :participation, reservation: reservation, user: user, cancelled: true
          }

          it "is valid" do
            expect(participation).to be_valid
          end
        end
      end
    end

    describe "#reservation" do
      context "validate presence" do
        it "adds error when absent" do
          participation.reservation = nil

          expect(participation).not_to be_valid
          expect(participation.errors).to include(:reservation)
        end

        it "is valid when present" do
          expect(participation).to be_valid
        end
      end

      context "validate group reservation" do
        it "adds error when not a group reservation" do
          participation.reservation = create(:reservation)

          error = I18n.t('activerecord.errors.models.participation.attributes.reservation.not_a_group_reservation')

          expect(participation).not_to be_valid
          expect(participation.errors).to include(:reservation)
          expect(participation.errors.messages[:reservation]).to include(error)
        end

        it "is valid when group reservation" do
          expect(participation).to be_valid
        end
      end

      context "validate filled group reservation" do
        before(:each) do
          group.update_attribute(:max_participants, 2)
          create :participation, reservation: reservation
        end

        it "adds error when reservation has max participants" do
          create :participation, reservation: reservation

          error = I18n.t('activerecord.errors.models.participation.attributes.reservation.filled_group_reservation')

          expect(participation).not_to be_valid
          expect(participation.errors).to include(:reservation)
          expect(participation.errors.messages[:reservation]).to include(error)
        end

        it "is valid when reservation has less than max participants" do
          expect(participation).to be_valid
        end
      end
    end

    describe "#price" do
      context "validate presence" do
        it "adds error when absent" do
          group.participation_price = nil # othervise it will set auto
          participation.price = nil

          expect(participation).not_to be_valid
          expect(participation.errors).to include(:price)
        end

        it "is valid when present" do
          expect(participation).to be_valid
        end
      end
    end
  end

  describe "#cancel" do
    let!(:participation) { create :participation, reservation: reservation, user: user }

    context 'cancels participation' do
      subject{ participation.cancel }

      it "updates cancelled to true" do
        expect{ subject }.to change{ Participation.active.count }.by(-1)
                         .and change{ Participation.cancelled.count }.by(1)
      end
    end

    context 'invoiced' do
      let!(:invoice) { Invoice.create_for_company(venue.company, participation.user) }

      it 'deletes participation invoice components' do
        expect(invoice.participation_invoice_components.count).to eq 1
        expect(invoice.participation_invoice_components.first.participation).to eq participation

        participation.cancel
        invoice.reload

        expect(invoice.participation_invoice_components.count).to eq 0
      end

      it 'recalculates invoice total' do
        expect(invoice.total).to eq participation.price

        participation.cancel
        invoice.reload

        expect(invoice.total).to eq 0
      end
    end

    context 'cancellation policy' do
      context 'refund to credit balance' do
        before(:each) do
          group.update_attribute(:cancellation_policy, :refund)
        end

        context 'paid' do
          before(:each) do
            participation.update_attribute(:is_paid, true)
          end

          it 'creates credit balance with correct associations' do
            expect{participation.cancel}.to change(Credit, :count).by(1)
            credit = Credit.last
            expect(credit.user).to eq user
            expect(credit.company).to eq venue.company
            expect(credit.balance).to eq participation.price
          end
        end

        context 'invoiced' do
          let!(:invoice) { Invoice.create_for_company(venue.company, participation.user) }

          before(:each) do
            invoice.send!
            participation.reload
          end

          it 'creates credit balance with correct associations' do
            expect{participation.cancel}.to change(Credit, :count).by(1)
            credit = Credit.last
            expect(credit.user).to eq user
            expect(credit.company).to eq venue.company
            expect(credit.balance).to eq participation.price
          end
        end

        context 'unpaid' do
          it 'does not create credit balance' do
            expect{participation.cancel}.not_to change(Credit, :count)
          end
        end
      end

      context 'refund to participation credit' do
        before(:each) do
          group.update_attribute(:cancellation_policy, :participation)
        end

        context 'paid' do
          before(:each) do
            participation.update_attribute(:is_paid, true)
          end

          it 'creates participation_credit with correct associations' do
            expect{participation.cancel}.to change(ParticipationCredit, :count).by(1)
            credit = ParticipationCredit.last
            expect(credit.user).to eq user
            expect(credit.company).to eq venue.company
            expect(credit.group_classification).to eq group.classification
          end
        end

        context 'invoiced' do
          let!(:invoice) { Invoice.create_for_company(venue.company, participation.user) }

          before(:each) do
            invoice.send!
            participation.reload
          end

          it 'creates participation_credit' do
            expect{participation.cancel}.to change(ParticipationCredit, :count).by(1)
          end
        end

        context 'unpaid' do
          it 'does not create participation_credit' do
            expect{participation.cancel}.not_to change(ParticipationCredit, :count)
          end
        end
      end
    end
  end

  describe 'before_validation :set_price' do
    let!(:participation) { build :participation, reservation: reservation, user: user }

    it 'sets calculated price' do
      expect(participation.price).to eq nil

      participation.save

      expect(participation.price).not_to eq nil
      expect(participation.price).to eq reservation.participation_price
    end

    it 'does not change existing price' do
      participation.price = 52342

      participation.save

      expect(participation.price).to eq 52342
      expect(participation.price).not_to eq reservation.participation_price
    end
  end
end
