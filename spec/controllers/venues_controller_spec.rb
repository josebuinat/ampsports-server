require 'rails_helper'

describe VenuesController, type: :controller do
  let (:company) { create(:company) }
  let (:venue) { create(:venue, :with_courts, :with_photos, company: company) }
  let (:court) { create(:court, :with_holidays, venue: venue) }
  let (:admin) { create(:admin, company: company) }

  describe "GET edit" do
    subject { get :edit, {id: venue.id}}

    context "with admin login" do
      before { sign_in(admin) }

      it "should return status 200" do
        expect(subject).to be_success
      end
    end
  end

  context '#holidays' do
    it 'returns a list of holidays' do
      sign_in(admin)
      get :holidays, venue_id: venue.id
      response_json = JSON.parse(response.body)
      expect(response_json.count).to eq(venue.holidays.count)
    end
  end

  context '#change_listed' do
    let(:params) { { status: Venue.statuses[:searchable],
                     venue_id: venue.id} }
    subject { post :change_listed, params }

    before do
      sign_in(admin)
    end

    context 'with valid params' do
      it 'is successful' do
        is_expected.to be_success
      end

      it 'changes status' do
        expect { subject }.to change{venue.reload.status}.to('searchable')
      end
    end

    it 'has to have courts' do
      venue.update(courts: [])
      expect(subject.status).to eq(422)
    end

    it 'has to have photos' do
      venue.update(photos: [])
      expect(subject.status).to eq(422)
    end

    it 'has to have business hours' do
      venue.update(business_hours: {})
      expect(subject.status).to eq(422)
    end

    it 'has a price for every court' do
      venue.courts.first.update(prices: [])
      expect(subject.status).to eq(422)
    end
  end

  context 'DELETE #destroy' do
    let!(:favourite_venue) { create :favourite_venue, venue: venue}
    subject { delete :destroy, id: venue.id }
    before { sign_in(admin) }
    it 'works' do
      expect { subject }.to change{ Venue.count }.by(-1)
      expect(response).to redirect_to company_path(venue.company)
    end
  end

  context '#available_court_indexes' do
    it 'is success' do
      sign_in(admin)
      get :available_court_indexes, id: venue.id, existing_court: court.id
      expect(response).to be_success
    end
  end

  context '#booking_sales_report' do
    let(:from) { in_venue_tz { Time.current.beginning_of_month.strftime('%d/%m/%Y') } }
    let(:to) { in_venue_tz { Time.current.end_of_month.strftime('%d/%m/%Y') } }
    it 'is success' do
      sign_in(admin)
      post :booking_sales_report, id: venue.id, report: { from: from, to: to }
      expect(response).to be_success
    end
  end
end
