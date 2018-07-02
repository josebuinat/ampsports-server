require 'rails_helper'

describe Admin::VenuesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    subject { get :index, format: :json }

    let!(:my_venue) { create :venue, :searchable, company: company }
    let!(:my_venue_not_listed) { create :venue, company: company }
    let!(:other_venue) { create :venue, :searchable }
    let(:body) { JSON.parse response.body }
    let(:venue_ids) { body['venues'].map { |x| x['id'] } }

    it 'renders all venues' do
      is_expected.to be_success
      expect(venue_ids).to match_array [my_venue.id, my_venue_not_listed.id]
    end
  end

  describe 'GET #show' do
    subject { get :show, format: :json, id: venue.id }

    let!(:venue) { create :venue, company: company }

    it { is_expected.to be_success }
  end

  describe 'GET #select_options_for_court_sports' do
    let!(:venue) { create :venue, :searchable, company: company }
    subject { get :select_options_for_court_sports, id: venue, format: :json }
    let(:body) { JSON.parse response.body }
    let(:sport_values) { body.map { |x| x['value'] }}
    let!(:court_1) { create :court, venue: venue, sport_name: :squash }
    let!(:court_2) { create :court, venue: venue, sport_name: :golf }
    let!(:court_3) { create :court, venue: venue, sport_name: :golf }

    it 'works' do
      is_expected.to be_success
      expect(sport_values).to match_array ['squash', 'golf']
    end
  end

  describe 'POST #create' do
    subject { post :create, format: :json, venue: params }

    let(:params) { {
      venue_name: 'some name',
      description: 'thorough description',
      booking_ahead_limit: 73,
      settings: settings_params
    } }
    let(:settings_params) { nil }

    it { is_expected.to be_success }

    it 'creates venue' do
      expect{ subject }.to change{ company.venues.count }.by(1)
    end

    context "with calendar settings" do
      let(:settings_params) do
        {
          calendar: {
            show_time: false
          }
        }
      end

      it 'updates setting value' do
        expect{ subject }.to change { Setting.count }.by(1)
        is_expected.to be_success
        expect(company.venues.last.settings(:calendar).get(:show_time)).to be_falsey
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, format: :json, id: venue.id, venue: params }

    let!(:venue) { create :venue, :searchable, company: company, custom_colors: { paid: '#654321' } }
    let!(:user) { create :user, venues: [venue] }
    let!(:discount) { create :discount, venue: venue, users: [user] }
    let(:params) { {
      venue_name: 'some name',
      description: 'thorough description',
      booking_ahead_limit: 73,
      custom_colors:  {
        unpaid: '#123456',
        paid: ''
      },
      user_colors: user_colors,
      discount_colors: discount_colors,
      business_hours: attributes_for(:venue).fetch(:business_hours),
      settings: settings_params
    } }
    let(:user_colors) { [{ user_id: user.id, color: '#123456' }] }
    let(:discount_colors) { [{ discount_id: discount.id, color: '#123456' }] }
    let(:settings_params) { nil }

    it { is_expected.to be_success }

    it 'updates colors' do
      expect { subject }. to change { venue.reload.custom_colors[:unpaid] }.to '#123456'
      is_expected.to be_success
    end

    it 'restores color to default' do
      expect { subject }. to change { venue.reload.custom_colors[:paid] }.to Venue::DEFAULT_COLORS[:paid]
      is_expected.to be_success
    end

    it 'updates user colors' do
      expect { subject }. to change { venue.reload.get_user_color(user) }.to '#123456'
      is_expected.to be_success
    end

    it 'updates discounts colors' do
      expect { subject }. to change { venue.reload.get_discount_colors([discount]) }.to ['#123456']
      is_expected.to be_success
    end

    context "with calendar settings" do
      let(:settings_params) do
        {
          calendar: {
            show_time: false
          }
        }
      end

      it 'updates setting value' do
        expect{ subject }.to change { Setting.count }.by(1)
          .and change{ venue.settings(:calendar).reload.get(:show_time) }.from(true).to(false)
        is_expected.to be_success
      end
    end
  end
end