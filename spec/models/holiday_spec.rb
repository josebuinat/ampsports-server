require 'rails_helper'

RSpec.describe Holiday, type: :model do
  let(:holiday) { create(:holiday, :with_courts) }

  describe '#as_json' do
    it 'has valid time_zone' do
      expect(holiday.as_json['start']).to eq(holiday.start_time.in_time_zone)
    end
  end

  it 'starts valid' do
    expect(holiday).to be_valid
  end

  it 'has a start_time' do
    holiday.start_time = nil
    expect(holiday).not_to be_valid
  end

  it 'has an end_date' do
    holiday.end_time = nil
    expect(holiday).not_to be_valid
  end

  it 'has valid range' do
    holiday.start_time = Time.zone.now.utc + 1.day
    holiday.end_time = Time.zone.now.utc - 1.day
    expect(holiday).not_to be_valid
  end

  it 'can handle one day ranges' do
    holiday.start_time = Time.zone.now.utc
    holiday.end_time = Time.zone.now.utc + 1.hour
    expect(holiday).to be_valid
  end

  it 'can handle multiple courts' do
    court1 = holiday.courts.first
    court2 = holiday.courts.second
    start_time = holiday.start_time.change(hour: 6, minute: 0, second: 0)
    end_time = holiday.end_time.change(hour: 7, minute: 0, second: 0)
    expect(court1.working?(start_time, end_time)).to be_falsey
    expect(court2.working?(start_time, end_time)).to be_falsey
  end

  context 'without all courts' do
    let(:start_time) { in_venue_tz { holiday.start_time.at_noon.in_time_zone.at_noon } }
    let(:venue) { holiday.courts.first.venue }
    let(:court_without_holiday) { create :court, :with_prices, venue: venue }
    let(:reservation_invalid) { build(:reservation, court: holiday.courts.first,
                                                    start_time: start_time) }
    let(:reservation_valid) { build(:reservation, court: court_without_holiday,
                                                  start_time: start_time) }
    it 'affects related courts' do
      expect(reservation_invalid).not_to be_valid
    end

    it 'does not affect other courts' do
      expect(reservation_valid).to be_valid
    end
  end

  describe 'sorting' do
    let!(:holiday_1) { create :holiday, :with_courts, court_count: 2 }
    let!(:holiday_2) { create :holiday, :with_courts, court_count: 4 }
    let!(:holiday_3) { create :holiday, :with_courts, court_count: 3 }

    subject { described_class.all.sort_on('courts_count desc') }
    it 'works' do
      is_expected.to eq [holiday_2, holiday_3, holiday_1]
    end
  end
end
