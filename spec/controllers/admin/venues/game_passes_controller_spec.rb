require 'rails_helper'

describe Admin::Venues::GamePassesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, company: company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }
    let(:game_pass_ids) { body['game_passes'].map { |x| x['id'] } }
    let!(:related_game_pass) { create :game_pass, venue: venue }
    let!(:unrelated_game_pass) { create :game_pass }

    it 'works' do
      is_expected.to be_success
      expect(game_pass_ids).to eq [related_game_pass.id]
    end
  end

  describe '#show' do
    subject { get :show, format: :json, venue_id: venue.id, id: game_pass.id }
    let!(:game_pass) { create :game_pass, venue: venue, time_limitations: time_limitations }
    let(:time_limitations) { [{ from: '07:00', to: '13:30', weekdays: ['mon', 'wed'] }] }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, game_pass: params }

    let!(:user) { create :user, venues: [venue] }

    context 'with valid params' do
      let(:created_game_pass) { GamePass.last }
      let(:params) { { user_id: user.id, total_charges: 5 } }

      it 'creates a game_pass' do
        expect { subject }.to change { venue.game_passes.not_templates.count }.by(1)
        is_expected.to be_created
      end

      it 'sets active to true if it has any charges' do
        is_expected.to be_created
        expect(created_game_pass).to be_active
      end

      context 'with coaches' do
        let(:params) { { user_id: user.id, total_charges: 5, coach_ids: [coach.id] } }

        let(:coach) { create :coach, company: company }

        it 'creates a game_pass with coach' do
          is_expected.to be_created

          expect(created_game_pass.coaches).to include coach

          expect(json).to include('coach_ids' => [coach.id])
        end
      end
    end

    context 'with invalid params' do
      # error: end time < start_time
      let(:params) { { user: nil, name: 'Hey', total_charges: 2 } }
      it 'does not work' do
        expect { subject }.not_to change { venue.game_passes.count }
        is_expected.to be_unprocessable
      end
    end

    context 'when creating a template' do
      let(:params) { { user_id: user.id, template_name: 'example' } }
      let(:created_template) { GamePass.templates.last}
      it 'creates a template game pass which is unassigned to a user' do
        # .templates kills scope, therefore has to use this fancy syntax
        expect { subject }.to change { venue.game_passes.not_templates.count }.by(1).
            and change { GamePass.where(venue_id: venue.id).count }.by(1)
        expect(created_template.user_id).to be_nil
        is_expected.to be_created
      end
    end
  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: game_pass.id, game_pass: params }
    let!(:game_pass) { create :game_pass, venue: venue }
    context 'with valid params' do
      let(:params) { { name: 'new name' } }
      it 'works' do
        expect { subject }.to change { game_pass.reload.name }.to('new name')
        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:params) { { user_id: nil } }
      it 'does not work' do
        expect { subject }.not_to change { game_pass.reload.user }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, format: :json, venue_id: venue.id, id: game_pass.id }
    let!(:game_pass) { create :game_pass, venue: my_venue }
    context 'with game pass I own' do
      let(:my_venue) { venue }
      it 'works' do
        expect { subject }.to change { venue.game_passes.count }.by(-1)
        is_expected.to be_success
      end
    end

    context 'with wrong game pass' do
      # not my venue
      let(:my_venue) { create :venue }
      it 'does not work' do
        expect { subject }.not_to change { venue.game_passes.count }
        is_expected.to be_not_found
      end
    end
  end

  describe '#destroy_many' do
    subject { delete :destroy_many, format: :json, venue_id: venue.id, game_pass_ids: game_pass_ids }
    let!(:game_pass_1) { create :game_pass, venue: venue }
    let!(:game_pass_2) { create :game_pass, venue: venue }
    let(:game_pass_ids) { [game_pass_1.id, game_pass_2.id] }
    it 'works' do
      expect { subject }.to change { venue.game_passes.count }.by(-2)
      is_expected.to be_success
    end
  end
end
