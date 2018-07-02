require 'rails_helper'
require 'stripe_mock'

describe API::InvoicesController, type: :controller do
  let(:user) { create(:user) }
  let(:invoices) { [
    create(:invoice, :with_ics, :with_gics, :with_pics, :with_gsics, :with_cics, owner: user, is_draft: false, is_paid: true),
    create(:invoice, :with_ics, :with_gics, :with_pics, :with_gsics, :with_cics, owner: user, is_draft: false),
    create(:invoice, :with_ics, :with_gics, :with_pics, :with_gsics, :with_cics, owner: user)
  ] }

  before do
		invoices.each(&:calculate_total!)
    invoices.each(&:reload)
    sign_in_for_api_with(user)
  end

  let(:response_json) { JSON.parse(response.body) }
  let(:invoices_ids) { response_json['invoices'].map { |invoice| invoice['id'] } }

  context '#index' do
    render_views
    subject { get :index }

    it 'returns correct list of paid invoices' do
      is_expected.to be_success
      expect(invoices_ids).to match_array(invoices.reject(&:is_draft).map(&:id))
    end
  end

  context '#show' do
    subject { get :show, id: invoices[0].id, format: :pdf }

    it 'is successful' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns pdf' do
      expect(subject).to render_template('invoices/show')
    end
  end

  context '#pay' do
    let(:stripe_helper) { StripeMock.create_test_helper }
    let(:card_token) { StripeMock.generate_card_token(last4: "9191", exp_year: 1984) }

    subject { post :pay, invoice_id: invoices[1].id, card: card_token}

    before { StripeMock.start }
    after { StripeMock.stop }

    it 'is successful' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'updates invoice' do
      expect{ subject }.to change{ invoices[1].reload.is_paid}.from(false).to(true)
    end
  end
end
