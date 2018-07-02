require 'rails_helper'

describe Admin::Reservations::LogsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    let!(:venue) { create :venue, company: company }
    let!(:court) { create :court, venue: venue }
    let!(:reservation) { create :reservation, court: court }
    subject { get :index, format: :json, reservation_id: reservation.id }

    let(:body) { JSON.parse response.body }
    let(:logs_ids) { body['logs'].map { |x| x['id'] } }
    it 'renders logs' do
      is_expected.to be_success
      expect(logs_ids).to match_array reservation.logs.map(&:id)
    end
  end

end
