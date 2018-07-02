require 'rails_helper'

describe Admin::Users::InvoicesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  let!(:venue) { create :venue, company: company }
  let(:user) { create :user, venues: [venue] }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    subject { get :index, format: :json, user_id: user.id }

    let!(:draft_invoice) { create :invoice, company: company, owner: user, is_draft: true }
    let!(:unpaid_invoice) { create :invoice, company: company, owner: user, is_draft: false, is_paid: false }
    let!(:paid_invoice) { create :invoice, company: company, owner: user, is_draft: false, is_paid: true }

    let(:body) { JSON.parse response.body }
    let(:invoice_ids) { body['invoices'].map { |x| x['id'] } }

    it 'returns all user invoices' do
      is_expected.to be_success
      expect(invoice_ids).to match_array [unpaid_invoice.id, paid_invoice.id]
    end
  end
end
