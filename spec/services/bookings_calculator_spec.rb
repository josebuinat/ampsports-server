require 'rails_helper'

describe BookingsCalculator, type: :service do
  let(:calculator) { described_class.new(company, venue_id, start_date, end_date).call }
  let(:start_date) { 4.weeks.since.to_date.strftime('%d/%m/%Y') }
  let(:end_date) { Date.today.strftime('%d/%m/%Y') }
  let(:company) { create :company }
  let(:venue_id) { nil }

  let!(:venue) { create :venue, :searchable, :with_courts, company: company }

  # this tests basically ensure that SQL requests doesn't die due to wrong syntax
  # good start to add more tests
  describe '#unpaid_count' do
    subject { calculator.unpaid_count }
    it { is_expected.to eq 0 }
  end

  describe '#to_be_invoiced_count' do
    subject { calculator.to_be_invoiced_count }
    it { is_expected.to eq 0}
  end

  describe '#invoiced_count' do
    subject { calculator.invoiced_count }
    it { is_expected.to eq 0}
  end

  describe '#paid_on_site_count' do
    subject { calculator.paid_on_site_count }
    it { is_expected.to eq 0}
  end

  describe '#paid_on_reservation_count' do
    subject { calculator.paid_on_reservation_count }
    it { is_expected.to eq 0}
  end

  describe '#booked_by_admin_count' do
    subject { calculator.booked_by_admin_count }
    it { is_expected.to eq 0}
  end

  describe '#paid_on_site' do
    subject { calculator.paid_on_site }
    it { is_expected.to eq 0}
  end

  describe '#paid_on_reservation' do
    subject { calculator.paid_on_reservation }
    it { is_expected.to eq 0}
  end

end