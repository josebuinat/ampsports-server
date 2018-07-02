require 'rails_helper'

describe Admin::Companies::CoachesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  let(:body) { JSON.parse response.body }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    subject { get :index, format: :json, **params }
    let!(:coach) { create :coach, company: company, level: :manager }
    let!(:other_coach) { create :coach, company: company, level: :manager }
    let!(:unrelated_coach) { create :coach, :with_company, level: :manager }
    let(:coach_ids) { body['coaches'].map { |x| x['id'] } }
    let(:params) { { search: nil } }

    it 'renders all coachs' do
      is_expected.to be_success
      expect(coach_ids).to match_array [coach.id, other_coach.id]
    end

    context 'with outstanding balance' do
      let(:params) { { with_outstanding_balance: true } }

      let!(:venue) { create :venue, company: company }
      let!(:court) { create :court, venue: venue }
      let!(:coach_with_balance) {
        create :coach, :available, company: company, for_court: court }
      let!(:unpaid_reservation) {
        create :reservation, user: coach_with_balance, price: 7.0, court: court
      }

      it 'renders coachs with balance' do
        is_expected.to be_success
        expect(coach_ids).to match_array [coach_with_balance.id]
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, format: :json, id: other_coach.id }

    context 'with coach from same company' do
      let(:other_coach) { create :coach, company: company, level: :manager }
      it { is_expected.to be_success}

      it 'returns manager level permissions' do
        is_expected.to be_success

        expect(json['permissions']).to include('coaches' => ['read'], 'admins' => [])
      end
    end

    context 'with coach from other company' do
      let(:other_coach) { create :coach, :with_company, level: :manager }
      it { is_expected.to be_not_found }
    end
  end

  describe 'POST #create' do
    subject { post :create, format: :json, coach: params }

    context 'with incorrect params' do
      # just email, need other params too
      let(:params) { { email: 'how@wow.com' } }
      it { is_expected.to be_unprocessable }
    end

    context 'with correct params' do
      let(:params) { attributes_for(:coach, level: :manager) }

      it 'works' do
        expect { subject }.to change(Coach, :count).by(1)
        is_expected.to be_created
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, id: other_coach.id, coach: params, format: :json }

    context 'with coach from my company' do
      let(:other_coach) { create :coach, level: :manager, company: company }
      context 'with valid params' do
        let(:params) { { first_name: 'Todd', sports: ['tennis', 'squash', 'unexisting'] } }

        it 'works' do
          expect { subject }.to change { other_coach.reload.first_name }.to('Todd')
                            .and change { other_coach.reload.sports }.to(['tennis', 'squash'])
          is_expected.to be_success
        end
      end

      context 'with invalid params' do
        let(:params) { { email: '' } }

        it 'does not work' do
          expect { subject }.not_to change { other_coach.reload.email }
          is_expected.to be_unprocessable
        end
      end
    end

    context 'with coach from other company' do
      let(:other_coach) { create :coach, :with_company, level: :manager }
      let(:params) { attributes_for :coach }
      it 'does not work' do
        expect { subject }.not_to change { other_coach.reload.attributes }
        is_expected.to be_not_found
      end
    end

    context 'with permissions' do
      let!(:other_coach) { create :coach, company: company, level: :base }
      let(:params) { { permissions: { coaches: [:read, :edit] } } }

      it 'updates permissions' do
        is_expected.to be_success

        expect(json['permissions']).to include('coaches' => ['read', 'edit'], 'admins' => [])
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, id: other_coach.id, format: :json }

    context 'when deleting someone from my company' do
      let!(:other_coach) { create :coach, company: company, level: :manager }
      it 'works' do
        expect { subject }.to change(Coach, :count).by(-1)
        is_expected.to be_success
      end
    end

    context 'when deleting someone from other company' do
      let!(:other_coach) { create :coach, :with_company, level: :manager }
      it 'does not work' do
        expect { subject }.not_to change(Coach, :count)
        is_expected.to be_not_found
      end
    end
  end

  describe '#destroy_many' do
    subject { delete :destroy_many, format: :json, coach_ids: [coach.id, unrelated_coach.id] }

    let!(:coach) { create :coach, company: company, level: :manager }
    let!(:other_coach) { create :coach, company: company, level: :manager }
    let!(:unrelated_coach) { create :coach, :with_company, level: :manager }

    it 'works' do
      expect { subject }.to change(Coach, :count).by(-1)
      is_expected.to be_success
      expect(body).to eq [coach.id]
    end
  end
end
