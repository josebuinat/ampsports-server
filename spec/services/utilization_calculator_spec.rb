require 'rails_helper'

describe UtilizationCalculator, type: :service do
  let(:calculator) { in_venue_tz { described_class.new(company, venue_id, start_date, end_date).call } }
  let(:start_date) { in_venue_tz { 2.weeks.from_now.to_date.strftime('%d/%m/%Y') } }
  let(:end_date) { start_date }
  let(:company) { create :company }
  let(:venue_id) { nil }
  let!(:venue) { create :venue, :searchable, company: company }
  # it works with a public_hours, so we need to create a proper filled_price from opening to closing times
  let!(:court_1){ create :court, venue: venue }
  let!(:court_2){ create :court, venue: venue }
  let!(:prices) do
    create :filled_price, courts: [court_1, court_2], start_minute_of_a_day: 360, end_minute_of_a_day: 1320
  end
  
  describe '#utilization_for' do
    let(:calculated_utilization) { in_venue_tz { calculator.utilization_for(court_1, Date.parse(start_date)) } }
    subject { calculated_utilization[0][:availability] }

    context 'when nothing booked' do
      it 'is full' do
        is_expected.to eq 1
      end
    end

    context 'when half booked' do
      let(:reservation_start_time) { in_venue_tz { Time.zone.parse(start_date).change(hour: 6) } }
      let!(:reservation) do
        create :reservation,
               court: court_1,
               start_time: reservation_start_time,
               end_time: reservation_start_time + 1.hour
      end

      it 'is half' do
        is_expected.to eq 0.5
      end

      context 'when fully booked' do
        let!(:reservation_2) do
          create :reservation,
                 court: court_1,
                 start_time: reservation_start_time + 1.hours,
                 end_time: reservation_start_time + 2.hours
        end

        it 'is zero' do
          is_expected.to eq 0
        end
      end
    end
  end

  describe '#value' do
    subject { calculator.value }
    let(:chunks_length) { calculator.value.size }
    let(:first_value) { calculator.value[0] }

    context 'when one court fully booked' do
      let(:reservation_start_time) { in_venue_tz{ Time.zone.parse(start_date).change(hour: 6) } }
      let!(:reservation) do
        create :reservation,
               court: court_1,
               start_time: reservation_start_time,
               end_time: reservation_start_time + 2.hours
      end

      context 'when requesting one day stats' do
        it 'returns correct result' do
          # it's about 6am - 8am, one court fully booked, one is free
          expect(first_value).to eq availability: 0.5, from: reservation_start_time, to: reservation_start_time + 2.hours
          expect(chunks_length).to eq 8
        end
      end

      context 'when requesting 7 days stats' do
        let(:end_date) { 20.days.from_now.to_date.strftime('%d/%m/%Y') }
        it 'returns correct result' do
          # it's about a full day, 2 hours for a full day (6-22) is 12,5%
          # or 12,5 / 2 = 6,25% for a venue with 2 courts
          from = in_venue_tz { venue.opening_local(Date.parse(start_date)) }
          to = in_venue_tz { venue.closing_local(Date.parse(start_date)) }
          expect(first_value).to eq availability: 1 - 0.0625, from: from, to: to
          expect(chunks_length).to eq 7
        end
      end

      context 'when requesting a month' do
        let(:end_date) { 39.days.since.to_date.strftime('%d/%m/%Y') }
        let!(:reservation_2) do
          create :reservation,
                 court: court_1,
                 start_time: reservation_start_time + 2.hours,
                 end_time: reservation_start_time + 16.hours
        end

        it 'returns correct result' do
          # it's not really a full month, just 39-13 = 26 days. Should return 4 weeks, last will be not "full"
          # ( still calculated based on reservations count though )
          # 1 day is busy totally (so 1 / 7) and 2 courts ( so / 2 )
          from = in_venue_tz { venue.opening_local(Date.parse(start_date)) }
          to = in_venue_tz { venue.closing_local(Date.parse(start_date) + 6) }
          expect(first_value).to eq availability: 1.0 - 1.0 / 7 / 2, from: from, to: to
        end

        it 'calculates total availability' do
          # and it respects that the last week is not full!
          expect(calculator.total_availability).to eq 1.0 - 1.0 / 26 / 2
        end
      end
    end
  end
end
