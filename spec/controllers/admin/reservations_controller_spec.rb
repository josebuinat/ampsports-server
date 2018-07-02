require 'rails_helper'

describe Admin::ReservationsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_courts, company: company, court_count: 1 }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe "DESTROY #destroy_many" do
    subject { delete :destroy_many, params}

    let!(:reservation) { create :reservation, court: venue.courts.first }
    let(:params) {{ reservation_ids: [reservation.id] }}

    it "should destroy the reservations" do
      expect { subject }.to change { Reservation.count }.by(-1)
      is_expected.to be_success
    end

    it_behaves_like "loggable activity", "reservation_cancelled"
  end
end
