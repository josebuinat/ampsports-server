require 'rails_helper'

describe Admin::Venues::UsersController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }
  let(:body) { JSON.parse response.body }

  # cannot connect user to company without venue
  let!(:venue) { create :venue, :searchable, company: company }

  describe 'POST #import' do
    subject { post :import, venue_id: venue.id, csv_file: users_csv_file }

    let(:users_csv_file) { fixture_file_upload('import/users.csv', 'text/csv') }

    it 'imports users' do
      expect { subject }.to change { company.users.reload.count }.by(2)
      is_expected.to be_created
      expect(company.users.last.email).to include 'john_dole_'
    end

    it 'returns report JSON' do
      is_expected.to be_created
      expect(body.dig('report', 'created_count')).to eq 2
      expect(body.dig('report', 'failed_count')).to eq 1
      expect(body.dig('report', 'failed_rows')).to be_any
      expect(body.dig('report', 'failed_rows')[0]['errors']).to be_present
    end
  end
end
