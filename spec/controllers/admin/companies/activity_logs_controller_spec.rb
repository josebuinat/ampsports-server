require 'rails_helper'

describe Admin::Companies::ActivityLogsController, type: :controller do
  render_views

  describe "GET index" do
    before :all do
      venue = create :venue, :with_courts
      @company = venue.company
      create_activity_logs(@company)
    end

    after :all do
      DatabaseCleaner.clean_with :truncation
    end

    let(:current_admin) { create :admin, company: @company }
    let(:params) { nil }
    let(:response_body) { JSON.parse(response.body.to_s) }

    before do
      sign_in_for_api_with current_admin
      get :index, params
    end

    subject { response }

    context "without any filters" do
      it { is_expected.to be_success }
      it "should render all logs" do
        expect(response_body['activity_logs'].size).to eq (3)
      end
    end

    context "with filters" do
      context "with search term" do
        let(:params) { {company_id: @company.id , search: {search_term: Reservation.first.user.first_name}.to_json }}

        it { is_expected.to be_success }
      end

      context "with filter_start_date" do
        let(:params) { {company_id: @company.id , search: {filter_start_date: DateTime.current.strftime('%Y-%m-%d')}.to_json }}

        it { is_expected.to be_success }
      end

      context "with filter_end_date" do
        let(:params) { {company_id: @company.id , search: {filter_end_date: DateTime.current.strftime('%Y-%m-%d')}.to_json }}

        it { is_expected.to be_success }
      end

      context "with filter_payload_types" do
        let(:params) { {company_id: @company.id , search: {filter_payload_types: 'reservation'}.to_json }}

        it { is_expected.to be_success }
        it "should render filtered results" do
          expect(response_body['activity_logs'].size).to eq(1)
        end
      end

      context "with filter_action_types" do
        let(:params) { {company_id: @company.id , search: {filter_action_types: 'sent'}.to_json }}

        it { is_expected.to be_success }
        it "should render filtered results" do
          expect(response_body['activity_logs'].size).to eq(1)
        end
      end
    end
  end
end
