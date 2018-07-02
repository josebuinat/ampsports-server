require 'rails_helper'

describe Search::Results::VenuePresenter, type: :service do
  let(:venue) { create :venue, :searchable }
  let!(:court) { create :court, :with_prices, venue: venue }
  let(:all_courts) { Array.new }
  let(:search) do
    Search::Global.new(
      sport_name: 'tennis',
      time: '2200',
      location: nil,
      duration: 60,
      date: Date.tomorrow,
      sort_by: nil
    ).call
  end

  describe 'lowest price' do
    context 'when user has a discount' do
      let(:user) { create :user, discounts: [ discount ] }
      let(:discount) { create :discount, venue: venue } # 50% discount as per factory

      subject { described_class.new(venue, search, user, all_courts).lowest_price }

      it { is_expected.to eql 5.0 }
    end

    context 'when there is no user' do
      subject { described_class.new(venue, search, nil, all_courts).lowest_price }

      it { is_expected.to eql 10.0 }
    end
  end
end
