require 'rails_helper'

describe Search::Results::CourtPresenter, type: :service do
  let(:venue) { create :venue }
  let(:court) { create :court, :with_prices, venue: venue }
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

  describe 'available_times' do
    subject { described_class.new(court, venue, search, nil).available_times }
    it 'has price' do
      expect(subject.map(&:price)).to all(be > 0)
    end

    it 'is in the same timezone as venue' do
      venue_timezone = ActiveSupport::TimeZone.new(venue.timezone).to_s
      expect(subject.map{ |time_frame| time_frame.starts.time_zone.to_s }).to all(eql(venue_timezone))
    end

    context 'with squash court' do
      let(:court) { create :court, :with_prices, venue: venue, sport_name: :squash }

      it 'returns 15 and 45 minutes start times' do
        expect(subject.map{ |time_frame| time_frame.starts.min }).to include(0, 15, 30, 45)
      end
    end
  end

  describe 'lowest price' do
    context 'when user has a discount' do
      let(:user) { create :user, discounts: [ discount ] }
      let(:discount) { create :discount, venue: venue } # 50% discount as per factory
      subject { described_class.new(court, venue, search, user).lowest_price }

      it { is_expected.to eql 5.0 }
    end

    context "when user doesn't have a discount" do
      subject { described_class.new(court, venue, search, nil).lowest_price }

      it { is_expected.to eql 10.0 }
    end
  end
end
