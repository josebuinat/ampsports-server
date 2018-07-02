require 'rails_helper'

describe CompaniesController, type: :controller do
  describe 'POST create' do
    context 'with admin signed in' do
      let(:admin) { create :admin }

      before { sign_in(admin) }

      context 'when the "Accept Stripe terms" checkbox checked' do
        let(:valid_params) do
          {
            company_legal_name: 'test',
            company_tax_id: '000000000',
            company_business_type: 'Osakeyhtiö',
            country_id: '2',
            company_street_address: '325 Sutter Street, Union Square',
            company_zip: '94108',
            company_city: 'San Francisco',
            company_website: 'example.com',
            usa_state: 'California',
            company_iban: '000123456789',
            company_phone: '3103073965',
            bank_name: 'Test bank',
            company_bic: '123123123',
            usa_routing_number: '110000000'
          }
        end

        let(:keys) do
          double(:stripe_keys, secret: 'secret_key', publishable: 'publishable_key')
        end

        let(:verification) do
          double(:stripe_verification, fields_needed: [], due_by: nil)
        end

        let(:stripe_account) do
          double(:stripe_account,
                 {
                   id: 'stripe_user_id',
                   default_currency: 'usd',
                   details_submitted: '',
                   charges_enabled: true,
                   transfers_enabled: true,
                   verification: verification,
                   keys: keys
                 }
          )
        end

        let(:param) { a_hash_including(external_account: a_hash_including(routing_number: '110000000')) }

        it 'creates an account in Stripe' do
          expect(Stripe::Account).to receive(:create).with(param).and_return(stripe_account)
          post :create, company: valid_params, tos: 'on'
          expect(response).to be_redirect
        end

        context 'when Stripe throws an exception error' do
          it 'informs user that Stripe account was not created' do
            allow(Stripe::Account).to receive(:create).and_raise(Stripe::StripeError)
            post :create, company: valid_params, tos: 'on'
            expect(flash[:error]).to eql 'Unable to create Stripe account!'
          end
        end
      end
    end

    context 'with admin not signed in' do
      it 'redirects to sign_in page' do
        post :create, company: {}, tos: 'on'
        expect(response).to redirect_to '/admins/sign_in'
      end
    end
    describe '#remove_user_from_qi' do
      let (:user) { create :user }
      let (:company) { create(:company, saved_invoice_users: [user]) }
      let (:admin) { create(:admin, company: company) }
      subject { post :remove_user_from_qi, { company_id: company.id,
                                             user_id: user.id } }

      before do
        sign_in(admin)
      end

      it 'removes user' do
        expect { subject }.to change { company.saved_invoice_users.count }.by(-1)
      end
    end

  end
end
