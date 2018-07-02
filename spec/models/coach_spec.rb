require 'rails_helper'

RSpec.describe Coach, type: :model do
  it "works" do
    expect(build :coach).to be_valid
    expect{ create :coach }.not_to raise_error
  end

  it_behaves_like "configurable clock_type" do
    subject { described_class.new }
  end

  describe '#available?' do
    subject{ in_venue_tz{ coach.available?(court, start_time, end_time) } }

    let!(:venue) { create :venue, :with_courts, court_counts: 1 }
    let!(:coach) { create :coach }
    let(:court) { venue.courts.first }
    let(:start_time) { in_venue_tz{ Time.current.advance(days: 1).at_noon } }
    let(:end_time) { start_time.advance(hours: 3) }
    let(:base_params) { { coach: coach, venue: venue, sport_name: court.sport_name } }

    context 'when one price exactly covers timeslot' do
      let!(:price_rate) {
        create :coach_price_rate, coach: coach,
                                  venue: price_venue,
                                  start_time: start_time,
                                  end_time: end_time,
                                  sport_name: price_sport
      }
      let(:price_venue) { venue }
      let(:price_sport) { court.sport_name }

      it{ is_expected.to be_truthy }

      context 'for different venue' do
        let(:price_venue) { create :venue }

        it{ is_expected.to be_falsey }
      end

      context 'for different sport' do
        let(:price_sport) { 'squash' }

        it{ is_expected.to be_falsey }
      end
    end

    context 'when price covers whole day and extends to next day' do
      let!(:price_rate) do
        create :coach_price_rate, start_time: start_time,
                                  end_time: start_time.advance(days: 1),
                                  **base_params
      end

      it{ is_expected.to be_truthy }
    end

    context 'when prices cover timeslot together' do
      let!(:price_rate1) do
        create :coach_price_rate, start_time: start_time,
                                  end_time: start_time.advance(hours: 1),
                                  **base_params
      end
      let!(:price_rate2) do
        create :coach_price_rate, start_time: start_time.advance(hours: 1),
                                  end_time: end_time,
                                  **base_params
      end

      it{ is_expected.to be_truthy }
    end

    context 'when no prices' do
      it{ is_expected.to be_falsey }
    end

    context 'when price does not cover timeslot' do
      let!(:price_rate) do
        create :coach_price_rate, start_time: start_time,
                                  end_time: start_time.advance(hours: 2),
                                  **base_params
      end

      it{ is_expected.to be_falsey }
    end

    context 'when prices cover start and end of timeslot except middle' do
      let!(:price_rate1) do
        create :coach_price_rate, start_time: start_time,
                                  end_time: start_time.advance(hours: 1),
                                  **base_params
      end
      let!(:price_rate2) do
        create :coach_price_rate, start_time: end_time.advance(hours: -1),
                                  end_time: end_time,
                                  **base_params
      end

      it{ is_expected.to be_falsey }
    end
  end

  describe '#price_at' do
    let!(:venue) { create :venue, :with_courts, court_counts: 1 }
    let!(:coach) { create :coach }
    let(:court) { venue.courts.first }
    let(:base_params) { { coach: coach, venue: venue, sport_name: court.sport_name } }
    let(:start_time) { in_venue_tz{ Time.current.advance(days: 1).at_noon } }
    let(:request_start_time) { start_time }
    let(:request_end_time) { request_start_time.advance(hours: 3) }

    let!(:price_rate1) do
      create :coach_price_rate,
        start_time: start_time,
        end_time: start_time.advance(hours: 1),
        rate: 10.0,
        **base_params
    end
    let!(:price_rate2) do
      create :coach_price_rate,
        start_time: start_time.advance(hours: 1),
        end_time: start_time.advance(hours: 4),
        rate: 20.0,
        **base_params
    end

    subject do
      coach.price_at(request_start_time, request_end_time, court)
    end

    it { is_expected.to eq(10.0 + 20.0 + 20.0) }

    context 'when unappliable' do
      let(:request_start_time) { in_venue_tz { 1.year.from_now.at_noon } }

      it { is_expected.to eq 0.0 }
    end

    context 'when partially applied' do
      let(:request_start_time) { start_time.advance(minutes: 30) }
      let(:request_end_time) { request_start_time.advance(hours: 1) }

      it do
        is_expected.to eq((10.0 + 20.0) * 0.5)
      end
    end
  end

  describe '#permissions' do
    let(:coach) { create :coach }

    context 'updating permissions' do
      subject{ coach.update permissions: permissions_params }

      let(:permissions_params) do
        { 'courts' => ['read'], groups: [:read, :edit], 'admins' => [] }
      end

      it 'updates permissions' do
        subject
        expect(coach.reload.permissions).
          to include(courts: ['read'], groups: ['read', 'edit'], admins: [], dashboard: [])
      end
    end

    context 'default permissions' do
      context 'when base' do
        let(:coach) { create :coach, level: :base }

        it 'returns base permissions' do
          expect(coach.permissions).
            to include(courts: [], profile: ['read', 'edit'], admins: [])
        end
      end

      context 'when manager' do
        let(:coach) { create :coach, level: :manager }

        it 'returns coach manager permissions' do
          expect(coach.permissions).
            to include(venues: ['read', 'edit'], coaches: ['read'], admins: [])
        end
      end
    end
  end
end
