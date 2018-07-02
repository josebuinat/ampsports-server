require 'rails_helper'

describe OutstandingBalances do
  describe '#membership_users' do
    let(:user) { create :user, :with_venues }
    let!(:membership) { create :membership, :with_reservations, user: user,  venue: user.venues.first }
    let(:ob) { OutstandingBalances.new(membership.venue.company) }
    subject { ob.membership_users }

    it 'returns list of users' do
      expect(subject.count).to eq(1)
    end
  end
end
