require 'rails_helper'
require 'stripe_mock'

describe Admin::ReportsController, type: :controller do
  render_views

  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:card_token) { StripeMock.generate_card_token(last4: "9191", exp_year: 1984) }
  let!(:current_admin) { create :admin, :with_company }
  let!(:venue) { create :venue, :searchable, company: current_admin.company }


  before { sign_in_for_api_with current_admin }

  describe '#index' do
    subject { get :index, format: :json }

    it { is_expected.to be_success }
  end

  describe '#payment_transfers json' do
    before { StripeMock.start }
    after { StripeMock.stop }

    subject { get :payment_transfers, format: :json }

    let(:json) { JSON.parse response.body }

    it 'returns transfers json' do
      is_expected.to be_success
      expect(json['transfers']).to eq []
    end
  end

  describe '#payment_transfers pdf' do
    before { StripeMock.start }
    after { StripeMock.stop }

    subject { get :payment_transfers, format: :pdf }

    it 'returns transfers file' do
      is_expected.to be_success
      expect(response.header['Content-Type']).to include 'application/pdf'
      expect(response.body).not_to eq '' # body should not be empty
      # can't use be_present bcause of 'invalid byte sequence in UTF-8'
    end
  end

  describe '#download_sales_report' do
    subject { get :download_sales_report, venue_id: venue.id }

    it 'returns report file' do
      is_expected.to be_success
      expect(response.header['Content-Type']).to include 'application/xlsx'
      expect(response.body).not_to eq '' # body should not be empty
    end
  end

  describe '#download_invoices_report' do
    subject { get :download_invoices_report, venue_id: venue.id }

    it 'returns report file' do
      is_expected.to be_success
      expect(response.header['Content-Type']).to include 'application/xlsx'
      expect(response.body).not_to eq '' # body should not be empty
    end
  end
end
