require 'rails_helper'

describe API::UserCountriesController, type: :controller do
  let(:venue) { create :venue }
  let(:user) { create :user, :with_favourites }

  describe 'PATCH update' do
    subject { patch :update, country_id: 2 }

    it 'returns "unauthorized" error' do
      expect(subject.status).to eq 401
    end
  end

  context 'when user is logged in' do
    before { sign_in_for_api_with(user) }

    describe 'PATCH update' do
      subject { patch :update, country_id: Country.find_country('US') }

      it 'is successful' do
        expect(subject.status).to eq 200
      end

      it 'sets user default country to USA' do
        subject
        expect(user.reload.default_country.name).to eql 'USA'
      end

      context 'when country not found' do
        subject { patch :update, country_id: 'some garbage' }

        it 'returns 404' do
          expect(subject.status).to eq 404
        end
      end
    end
  end
end
