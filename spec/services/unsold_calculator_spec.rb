require 'rails_helper'

describe UnsoldCalculator, type: :service do
  let(:calculator) { in_venue_tz { described_class.new(company, venue_id, start_date, end_date).call } }
  let(:start_date) { 2.weeks.from_now.to_date.strftime('%d/%m/%Y') }
  let(:end_date) { start_date }
  let(:company) { create :company }
  let(:venue_id) { nil }

  let!(:venue) { create :venue, :searchable, company: company }

  describe '#free_hours_for_court' do
    subject { in_venue_tz { calculator.missed_stuff_for_court(court, Date.parse(start_date)) } }
    let!(:court) { create :court, :with_prices, venue: venue, duration_policy: duration_policy }
    let(:reservation_start_time) do
      in_venue_tz do
        Time.zone.parse(start_date).change(hour: 6)
      end
    end

    let!(:reservation) do
      create :reservation,
             court: court,
             start_time: reservation_start_time,
             end_time: reservation_start_time + 2.hours
    end

    context 'with 30 min duration policy' do
      let(:duration_policy) { :any_duration }
      it 'calculates correct amount' do
        # 6 - 22 open, 16 hours working, 2 hours booked
        is_expected.to eq hours: 14, profit: 140
      end
    end

    context 'with hour duration policy' do
      let(:duration_policy) { :one_hour }
      # is not different between any_duration / one_hour
      # (starting times should be aligned though)
      it { is_expected.to eq hours: 14, profit: 140 }
    end
  end

  describe '#summary' do
    subject { calculator.summary }
    let(:end_date) { (Date.parse(start_date) + 1).strftime('%d/%m/%Y') }
    let!(:court_1) { create :court, :with_prices, venue: venue }
    let(:reservation_start_time_1) do
      in_venue_tz do
        Time.zone.parse(start_date).change(hour: 6)
      end
    end
    let!(:reservation_1) do
      create :reservation,
             court: court_1,
             start_time: reservation_start_time_1,
             end_time: reservation_start_time_1 + 2.hours
    end

    let!(:court_2) { create :court, venue: venue }
    let!(:price_1) { create :filled_price, courts: [court_2], end_minute_of_a_day: 600, price: 20 }
    let!(:price_2) { create :filled_price, courts: [court_2], start_minute_of_a_day: 600, price: 10 }
    let(:reservation_start_time_2) { in_venue_tz { Time.zone.parse(start_date).change(hour: 8) } }
    let!(:reservation_2) do
      create :reservation,
             court: court_2,
             start_time: reservation_start_time_2,
             end_time: reservation_start_time_2 + 1.hours
    end

    it 'calculates correct hours and prices' do
      # hours: 6 - 22 open, 16 hours per court, 2 courts, booked 2 + 1 = 29 hours free one day
      # other day is completely free - 32 hours
      # profit: 1 court 6 - 10am costs 20 (1h booked, 2 days) - 4h * 2d * $20 - $20
      # 10-22 costs 10, 2 days - 12h * 2d * $10
      # other court, 2 courts for 16 hours for 10$, and 2 hours were booked
      is_expected.to eq hours: 29 + 32, profit: ((4 * 2 * 20 - 20) + (12 * 2 * 10) + (16 * 2 * 10 - 20))
    end
  end

end