require 'rails_helper'

describe API::DiscountsController, type: :request do

  let!(:venue) { create :venue }

  let(:valid_params) do
    {
      discount: attributes_for(:discount),
      venue_id: venue.id,
      id: discount.id
    }
  end

  let(:invalid_params) do
    {
      discount: { name: 'test', value: '' },
      venue_id: venue.id,
      id: discount.id
    }
  end

  let(:discount) { create :discount, venue: venue }
  let(:create_endpoint) { "/api/venues/#{venue.id}/discounts" }
  let(:update_endpoint) { "/api/discounts/#{discount.id}" }

  context 'with valid params' do
    login_admin
    it 'will be created successfully' do
      post create_endpoint, valid_params
      expect(response).to have_http_status(201)
    end

    it 'will be updated successfully' do
      patch update_endpoint, valid_params
      expect(response).to have_http_status(204)
    end

    it 'will give the discount as json' do
      get "/api/discounts/#{discount.id}", valid_params
      response_json = JSON.parse(response.body)
      expect(response_json['value']).to eql 50.0
    end
  end

  context 'with invalid params' do
    login_admin
    it 'will not be created' do
      post create_endpoint, invalid_params
      expect(response).to have_http_status(422)
    end

    it 'will not be updated' do
      patch update_endpoint, invalid_params
      expect(response).to have_http_status(422)
    end
  end

  context 'without an admin' do
    it 'will not create discount' do
      post create_endpoint, valid_params
      expect(response).to have_http_status(401)
    end

    it 'will not update discount' do
      patch update_endpoint, valid_params
      expect(response).to have_http_status(401)
    end
  end
end
