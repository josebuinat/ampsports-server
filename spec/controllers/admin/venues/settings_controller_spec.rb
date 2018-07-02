require "rails_helper"

describe Admin::Venues::SettingsController, type: :controller do
  render_views

  before { sign_in_for_api_with current_admin }

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  let!(:venue) { create :venue, company: company }
  let(:settings_scope) { 'calendar' }

  describe '#index' do
    subject { get :index, { venue_id: venue.id, scope: settings_scope } }

    context 'with an invalid scope' do
      let(:settings_scope) { 'invalid' }

      it 'returns error' do
        is_expected.to be_unprocessable
        expect(json['errors']).to include(I18n.t('errors.settings.invalid_scope'))
      end
    end

    context "with calendar scope" do
      it 'returns calendar settings' do
        is_expected.to be_success
        expect(json['calendar']).to include('name' => 'show_time', 'value' => true)
      end
    end
  end
end
