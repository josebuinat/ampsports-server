require 'rails_helper'

RSpec.describe Credit, type: :model do
  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_users, :with_courts, court_count: 1, company: company }
  let!(:user) { venue.users.first }

  context 'optional dependency to creditable' do
    let(:reservation) { create :reservation }

    it 'creates without creditable' do
      credit = create(:credit, company: company, user: user)

      expect(credit.persisted?).to be_truthy
    end

    it 'creates with creditable' do
      credit = create(:credit, company: company, user: user, creditable: reservation)

      expect(credit.persisted?).to be_truthy
      expect(credit.reload.creditable).to eq reservation
    end
  end

  context 'validations' do
    let(:credit) { build(:credit, company: company, user: user) }

    describe "#user" do
      context "validate presence" do
        it "adds error when absent" do
          credit.user = nil

          credit.valid?
          expect(credit.errors).to include(:user)
        end

        it "is valid when present" do
          expect(credit.valid?).to be_truthy
          expect(credit.errors).not_to include(:user)
        end
      end
    end

    describe "#company" do
      context "validate presence" do
        it "adds error when absent" do
          credit.company = nil

          credit.valid?
          expect(credit.errors).to include(:company)
        end

        it "is valid when present" do
          expect(credit.valid?).to be_truthy
          expect(credit.errors).not_to include(:company)
        end
      end
    end
  end
end
