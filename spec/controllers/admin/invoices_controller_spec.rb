require 'rails_helper'

describe Admin::InvoicesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  let!(:venue) { create :venue, company: company }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    subject { get :index, format: :json, type: type }
    let!(:draft_invoice) { create :invoice, company: company, is_draft: true }
    let!(:unpaid_invoice) { create :invoice, company: company, is_draft: false, is_paid: false }
    let!(:paid_invoice) { create :invoice, company: company, is_draft: false, is_paid: true }
    let!(:other_invoice) { create :invoice, is_draft: true }

    let(:body) { JSON.parse response.body }
    let(:invoice_ids) { body['invoices'].map { |x| x['id'] } }

    context 'when searching drafts' do
      let(:type) { 'drafts' }
      it 'finds all drafts' do
        is_expected.to be_success
        expect(invoice_ids).to eq [draft_invoice.id]
      end
    end

    context 'when searching unpaid' do
      let(:type) { 'unpaid' }
      it 'finds all unpaid' do
        is_expected.to be_success
        expect(invoice_ids).to eq [unpaid_invoice.id]
      end
    end

    context 'when searching paid invoices' do
      let(:type) { 'paid' }
      it 'finds all paid invoices' do
        is_expected.to be_success
        expect(invoice_ids).to eq [paid_invoice.id]
      end
    end
  end

  describe 'GET #show' do
    let!(:invoice) { create :invoice, company: company }
    subject { get :show, format: :json, id: invoice.id }

    it { is_expected.to be_success }
  end

  describe 'POST #create' do
    let(:user) { create :user }
    let(:subject) { post :create, params }
    let(:component_params) { {name: 'custom', price: 10, vat_decimal: 0.1} }
    let(:params) do
      {
        owner_id: user.id,
        owner_type: 'User',
        custom_invoice_components_attributes: [component_params]
      }
    end

    context 'with valid params' do
      it 'works' do
        expect { subject }.to change{ company.invoices.count }.by(1)
        is_expected.to be_created
      end

      context 'with multiple components' do
        let(:params) do
          {
            owner_id: user.id,
            owner_type: 'User',
            custom_invoice_components_attributes: [component_params, component_params]
          }
        end

        it 'works' do
          expect { subject }.to change{ CustomInvoiceComponent.count }.by(2)
        end
      end

      context 'for coach' do
        let(:coach) { create :coach, company: company }
        let(:params) do
          {
            owner_id: coach.id,
            owner_type: 'Coach',
            custom_invoice_components_attributes: [component_params]
          }
        end

        it 'works' do
          expect { subject }.to change{ company.invoices.count }.by(1)
          is_expected.to be_created
          expect(company.invoices.last.owner).to eq coach
        end
      end
    end

    context 'with invalid params' do
      let(:component_params) { {name: nil, price: 1, vat_decimal: 1} }
      let(:parsed_json) { JSON.parse(response.body) }

      context "for custom invoice" do
        it 'renders errors' do
          expect { subject }.to do_not_change { Invoice.count }
          expect(parsed_json['errors']).to eql({'custom_invoice_components.name' => ["can't be blank"]})
          is_expected.to be_unprocessable
        end
      end

      context "for user" do
        let(:params) { {owner_id: nil, custom_invoice_components_attributes: []} }
        it 'renders errors' do
          expect { subject }.to do_not_change { Invoice.count }
          expect(parsed_json['errors']).to eql({'owner' => ["can't be blank"]})
          is_expected.to be_unprocessable
        end
      end
    end
  end

  describe 'POST #create_drafts' do
    subject{ post :create_drafts, params }

    let(:params) do
      {
        user_ids: user_ids,
        coach_ids: coach_ids,
        user_type: user_type,
        save_users: save_users,
        custom_biller_id: custom_biller_id,
      }
    end
    let(:user_ids) { [] }
    let(:coach_ids) { [] }
    let(:user_type) { '' }
    let(:save_users) { false }
    let(:custom_biller_id) { nil }

    context 'when have user to invoice' do
      let!(:user_with_balance) { create :user, venues: [venue] }
      let!(:unpaid_game_pass) { create :game_pass, venue: venue, user: user_with_balance }
      let(:user_ids) { [user_with_balance.id] }

      it 'creates draft for user' do
        expect { subject }.to change{ Invoice.count }.by(1)
        is_expected.to be_success
      end

      it 'adds user to recent' do
        expect { subject }.to change{ company.recent_invoice_users.count }.by(1)

        is_expected.to be_success
      end

      context 'when save_users param sent' do
        let(:save_users) { true }

        it 'adds user to saved' do
          expect { subject }.to change{ company.saved_invoice_users.count }.by(1)

          is_expected.to be_success
        end
      end

      context 'when user_type all_users was sent' do
        let!(:user_with_balance2) { create :user, venues: [venue] }
        let!(:unpaid_game_pass2) { create :game_pass, venue: venue, user: user_with_balance2 }

        let(:user_type) { 'all_users' }

        it 'creates drafts for all users' do
          expect { subject }.to change{ Invoice.count }.by(2)
          is_expected.to be_success
        end
      end

      context 'when coach_ids was sent' do
        let!(:court) { create :court, :with_prices, venue: venue }
        let!(:coach) { create :coach, :available, company: company, for_court: court }
        let!(:reservation) { create :reservation, court: court, user: coach }
        let!(:other_coach) { create :coach, :available, company: company, for_court: court }
        let!(:other_reservation) { create :reservation, court: court, user: other_coach,
                                                        start_time: reservation.end_time }

        let(:coach_ids) { [coach.id] }

        it 'creates drafts for all coaches' do
          expect { subject }.to change{ Invoice.count }.by(1)
          is_expected.to be_success
          expect(Invoice.last.owner).to eq coach
        end
      end

      context 'when user_type all_coaches was sent' do
        let!(:court) { create :court, :with_prices, venue: venue }
        let!(:coach) { create :coach, :available, company: company, for_court: court }
        let!(:reservation) { create :reservation, court: court, user: coach }

        let(:user_type) { 'all_coaches' }

        it 'creates drafts for all coaches' do
          expect { subject }.to change{ Invoice.count }.by(1)
          is_expected.to be_success
          expect(Invoice.last.owner).to eq coach
        end
      end

      context 'create invoice with custom_biller' do
        let(:custom_biller_id) { custom_biller.id }
        let(:group_with_biller) { create :group, :with_custom_biller, venue: venue }
        let(:court) { create :court, :with_prices, venue: venue }
        let(:user1) { create :user, venues: [venue] }
        let(:user2) { create :user, venues: [venue] }
        let(:user3) { create :user, venues: [venue] }
        let!(:reservation_with_biller) { create :reservation, :paid, user: group_with_biller, court: court }
        let!(:reservation_without_biller) { create :group_reservation, :paid, court: court,
                                              start_time: reservation_with_biller.start_time.advance(hours: 2) }
        let(:custom_biller) { group_with_biller.custom_biller }
        let!(:participation1) { create :participation, user: user1, reservation: reservation_with_biller }
        let!(:participation2) { create :participation, user: user2, reservation: reservation_with_biller }
        let!(:other_participation) { create :participation, user: user3, reservation: reservation_without_biller }

        context 'for all_users' do
          let(:user_type) { 'all_users' }

          it 'creates draft for all users with requested custom biller' do
            expect { subject }.to change{ custom_biller.invoices.count }.by(2)
            is_expected.to be_success
            expect(custom_biller.invoices.map(&:owner_id)).to match_array([participation1.user_id, participation2.user_id])
          end
        end

        context 'for selected users' do
          let(:user_ids) { [participation2.user_id, other_participation.user_id] }

          it 'creates draft only for selected users with requested custom biller' do
            expect { subject }.to change{ custom_biller.invoices.count }.by(1)
            is_expected.to be_success
            expect(custom_biller.invoices.last.owner_id).to eq participation2.user_id
          end
        end
      end
    end

    context 'without user to invoice' do
      let(:json) { JSON.parse(response.body) }

      it 'renders errors' do
        expect { subject }.not_to change{ Invoice.count }
        is_expected.to be_unprocessable
        expect(json['message']).to eq 'Please select some users'
      end
    end
  end

  describe 'PATCH #send_all' do
    let!(:invoice) { create :invoice, company: company, is_draft: true, is_paid: false }
    subject { patch :send_all, invoice_ids: invoice_ids, due_date: due_date, format: :json, **params }
    let(:invoice_ids) { [invoice.id] }
    let(:due_date) { Date.tomorrow.strftime('%d/%m/%Y') }
    let(:params) { { } }
    let(:delivery_email) { ActionMailer::Base.deliveries.last.from.first }

    it 'works' do
      expect { subject }.to change { invoice.reload.is_draft }.from(true).to(false)
                        .and change{ ActionMailer::Base.deliveries.count }.by(1)
      expect(delivery_email).to eq (company.invoice_sender_email || "no-reply@playven.com")
      is_expected.to be_success
    end

    it_behaves_like "loggable activity", 'invoices_sent'

    context 'with custom email' do
      context 'when company' do
        let(:params) { { sender: 'company' } }

        it 'sends email from company email' do
          expect { subject }.to change{ ActionMailer::Base.deliveries.count }.by(1)
          expect(delivery_email).to eq company.invoice_sender_email
          is_expected.to be_success
        end
      end

      context 'when admin' do
        let(:params) { { sender: 'admin' } }

        it 'sends email from admin email' do
          expect { subject }.to change{ ActionMailer::Base.deliveries.count }.by(1)
          expect(delivery_email).to eq current_admin.email
          is_expected.to be_success
        end
      end

      context 'when custom' do
        let(:params) { { sender: 'custom', sender_email: 'very_custom@mail.com' } }

        it 'sends email from custom email' do
          expect { subject }.to change{ ActionMailer::Base.deliveries.count }.by(1)
          expect(delivery_email).to eq 'very_custom@mail.com'
          is_expected.to be_success
        end
      end
    end
  end

  describe 'PATCH #unsend_all' do
    let!(:invoice) { create :invoice, company: company, is_draft: false, is_paid: false }
    subject { patch :unsend_all, invoice_ids: invoice_ids, format: :json, **params }
    let(:invoice_ids) { [invoice.id] }
    let(:params) { { } }

    it 'works' do
      expect { subject }.to change { invoice.reload.is_draft }.from(false).to(true)
      is_expected.to be_success
    end

    context 'with custom email' do
      let(:delivery_email) { ActionMailer::Base.deliveries.last.from.first }

      context 'when company' do
        let(:params) { { sender: 'company' } }

        it 'sends email from company email' do
          expect { subject }.to change{ActionMailer::Base.deliveries.count}.by(1)
          expect(delivery_email).to eq company.invoice_sender_email
          is_expected.to be_success
        end
      end

      context 'when admin' do
        let(:params) { { sender: 'admin' } }

        it 'sends email from admin email' do
          expect { subject }.to change{ActionMailer::Base.deliveries.count}.by(1)
          expect(delivery_email).to eq current_admin.email
          is_expected.to be_success
        end
      end

      context 'when custom' do
        let(:params) { { sender: 'custom', sender_email: 'very_custom@mail.com' } }

        it 'sends email from custom email' do
          expect { subject }.to change{ActionMailer::Base.deliveries.count}.by(1)
          expect(delivery_email).to eq 'very_custom@mail.com'
          is_expected.to be_success
        end
      end
    end
  end

  describe 'GET #print_all' do
    let!(:invoice) { create :invoice, company: company, is_draft: true, is_paid: false }
    subject { get :print_all, invoice_ids: invoice_ids, format: :pdf, auth_token: "SECRETTOKEN" }
    let(:invoice_ids) { [invoice.id] }
    it { is_expected.to be_success }
  end

  describe 'PATCH #mark_paid' do
    let!(:invoice) { create :invoice, company: company, is_draft: false, is_paid: false }
    subject { get :mark_paid, invoice_ids: invoice_ids, format: :pdf }
    let(:invoice_ids) { [invoice.id] }
    it 'works' do
      expect { subject }.to change { invoice.reload.is_paid }.from(false).to(true)
      is_expected.to be_success
    end
  end

  describe 'DESTROY #destroy_many' do
    let!(:invoice) { create :invoice, company: company, is_draft: true, is_paid: false }
    subject { get :destroy_many, invoice_ids: invoice_ids, format: :json }
    let(:invoice_ids) { [invoice.id] }
    it 'works' do
      expect { subject }.to change(Invoice, :count).by(-1)
      is_expected.to be_success
    end
  end

end
