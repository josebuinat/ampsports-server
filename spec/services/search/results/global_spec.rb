require 'rails_helper'

describe Search::Results::Global, type: :service do
  let(:search_instance) do
    Search::Global.new(
      sport_name: 'tennis',
      time: '2200',
      location: location_param,
      duration: duration_param,
      date: date_param,
      sort_by: nil
    ).call
  end

  let(:duration_param) { 60 }
  let(:date_param) { Date.tomorrow }
  let(:location_param) { nil }

  let(:foo_venue) { create :venue, :searchable }
  let(:bar_venue) { create :venue, :searchable }
  let!(:foo_court_1) { create :court, :with_prices, venue: foo_venue }
  let!(:foo_court_2) { create :court, :with_prices, venue: foo_venue, active: false }
  let!(:bar_court_1) { create :court, :with_prices, venue: bar_venue }

  describe '#wrap all_courts' do
    subject { described_class.new(search_instance).wrap(nil).all_courts }
    it 'returns only available courts' do
      is_expected.to match_array [foo_court_1, bar_court_1]
    end
  end

  describe '#wrap venues' do
    subject { described_class.new(search_instance).wrap(nil).venues }
    it 'returns venue-like objects' do
      expect(subject.count).to eql 2
    end

    describe 'first venue' do
      subject { described_class.new(search_instance).wrap(nil).venues.first }

      it 'has calculated lowest price ' do
        expect(subject.lowest_price).to eql 10.0
      end

      context 'when user has a discount' do
        subject { described_class.new(search_instance).wrap(user).venues.first }
        let(:user) { create :user, discounts: [ foo_discount, bar_discount ] }
        let(:foo_discount) { create :discount, venue: foo_venue } # 50% discount as per factory
        let(:bar_discount) { create :discount, venue: bar_venue } # 50% discount as per factory
        it 'applies discount to price' do
          expect(subject.lowest_price).to eql 5.0
        end
      end

      it 'has venue properties' do
        expect(subject.id).to be
        expect(subject.venue_name).to be
        expect(subject.description).to be
      end

      it 'has courts' do
        expect(subject.courts).to be
      end

      describe 'first court' do
        subject { described_class.new(search_instance).wrap(nil).venues.first.courts.first }

        it 'has court properties copied (id and name)' do
          expect(subject.id).to be
          expect(subject.court_name).to be
        end

        it 'has calculated lowest price' do
          expect(subject.lowest_price).to eql 10.0
        end

        it 'has calculated available times' do
          expect(subject.available_times.count).to eql 31
        end

        describe 'available times' do
          subject { venue.courts.first.available_times }
          let(:venue) { described_class.new(search_instance).wrap(nil).venues.first }

          it 'has price greater than zero' do
            expect(subject.map(&:price)).to all(be > 0)
          end

          it 'is in the same timezone as venue' do
            venue_timezone = ActiveSupport::TimeZone.new(venue.timezone).to_s
            expect(subject.map{ |time_frame| time_frame.starts.time_zone.to_s }).to all(eql(venue_timezone))
          end
        end
      end
    end
  end
end
