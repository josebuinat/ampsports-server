require 'rails_helper'

RSpec.describe ParticipationCredit, type: :model do
  it 'can be created' do
    expect{create :participation_credit}.not_to raise_error
  end

  context 'validations' do
    subject { participation_credit }

    let(:participation_credit) { build :participation_credit }

    describe "#user" do
      context "validate presence" do
        it "adds error when absent" do
          subject.user = nil

          expect(subject).not_to be_valid
          expect(subject.errors).to include(:user)
        end

        it "is valid when present" do
          expect(subject).to be_valid
        end
      end
    end

    describe "#company" do
      context "validate presence" do
        it "adds error when absent" do
          subject.company = nil

          expect(subject).not_to be_valid
          expect(subject.errors).to include(:company)
        end

        it "is valid when present" do
          expect(subject).to be_valid
        end
      end
    end

    describe "#group_classification" do
      context "validate presence" do
        it "adds error when absent" do
          subject.group_classification = nil

          expect(subject).not_to be_valid
          expect(subject.errors).to include(:group_classification)
        end

        it "is valid when present" do
          expect(subject).to be_valid
        end
      end
    end
  end

  context 'scopes' do
    describe "#applicable_reservations" do
      subject{ participation_credit.applicable_reservations }

      let!(:venue) { create :venue, :with_courts, court_count: 1 }
      let!(:user) { create :user, venues: [venue], skill_level: 6.5 }
      let!(:group) { create :group, venue: venue, max_participants: 1, skill_levels: [6.5] }
      let!(:participation_credit) {
        create :participation_credit, group_classification: group.classification,
                                      company: venue.company,
                                      user: user
      }

      context "when reservation for applicable group" do
        let!(:reservation) { create :reservation, user: group, court: venue.courts.first }

        it "returns reservation" do
          is_expected.to include(reservation)
        end

        context 'when reservation is filled' do
          let!(:existion_participation) { create :participation, reservation: reservation }

          it "does not return reservation" do
            is_expected.not_to include(reservation)
          end
        end

        context 'when user skill level does not match group' do
          before(:each) do
            user.update(skill_level: 7)
          end

          it "does not return reservation" do
            is_expected.not_to include(reservation)
          end
        end
      end

      context "when reservation for not applicable group" do
        let!(:other_classification_group) { create :group, venue: venue }
        let!(:reservation) { create :reservation, user: other_classification_group }

        it "does not return reservation" do
          is_expected.not_to include(reservation)
        end
      end

      context "when other company reservation" do
        let!(:other_company_reservation) { create :reservation, user: group }

        it "does not return reservation" do
          is_expected.not_to include(other_company_reservation)
        end
      end
    end
  end
end
