require 'rails_helper'

describe CustomInvoiceComponentsController do
  describe '#vat' do
    it 'returns list of vats' do
      get :vat
      response_json = JSON.parse(response.body)
      expect(response_json.count).to eq(CustomInvoiceComponent::DEFAULT_VAT_DECIMALS.count)
    end
  end
end
