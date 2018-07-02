require 'rails_helper'

describe RevenueCalculator, type: :service do
  let(:calculator) { described_class.new(company, venue_id, start_date, end_date).call }
  let(:start_date) { 14.days.from_now.strftime('%d/%m/%Y') }
  let(:end_date) { 15.days.from_now.strftime('%d/%m/%Y') }
  let(:company) { create :company }
  let(:venue_id) { nil }

  let!(:venue) { create :venue, :searchable, :with_courts, company: company }
  let!(:reservation_1) do
    create :reservation,
           court: venue.courts.first,
           amount_paid: 100,
           price: 150,
           start_time: in_venue_tz { TimeSanitizer.input("#{start_date} 10:00") }
  end
  let!(:reservation_2) do
    create :reservation,
           court: venue.courts.first,
           amount_paid: 20,
           price: 150,
           start_time: in_venue_tz { TimeSanitizer.input("#{end_date} 8:00") }
  end
  let!(:reservation_3) do
    create :reservation,
           court: venue.courts.last,
           amount_paid: 30,
           price: 30,
           start_time: in_venue_tz { TimeSanitizer.input("#{start_date} 10:00") }
  end

  describe '#total' do
    subject { calculator.total }
    it 'sums amounts' do
      is_expected.to eq 330
    end
  end

  describe '#chunks' do
    subject { calculator.chunks.transform_values(&:to_i).transform_keys(&:to_i) }
    it 'chunkifies the result' do
      is_expected.to eq 150 => 300, 30 => 30
    end
  end

end