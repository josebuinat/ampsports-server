require 'rails_helper'

describe API::CitiesController, type: :controller do
  render_views

  describe '#index' do
    subject { get :index, format: :json }
    let(:response_cities) { JSON.parse(subject.body)['cities'] }

    let!(:venue_1) { create :venue, :searchable, city: 'Bangkok' }
    let!(:venue_2) { create :venue, :searchable, city: 'BanGKok' }
    let!(:venue_3) { create :venue, :searchable, city: 'Dubai' }
    let!(:venue_4) { create :venue, :searchable, city: 'DUBAI' }
    let(:usa_company) { create :usa_company }
    let!(:venue_5) { create :venue, :searchable, city: 'san jose', company: usa_company }

    it 'works' do
      expect(response_cities).to match_array ['Bangkok', 'Dubai', 'San Jose']
    end

    context 'when country parameter is present' do
      subject { get :index, country: '2', format: :json }
      it 'returns cities for that country only' do
        expect(response_cities).to match_array ['San Jose']
      end
    end
  end
end
