require 'rails_helper'

describe InvoicesController do
  let!(:venue) { create :venue  }
  let(:company) { venue.company }
  let!(:court) { create :court, venue: venue }
  let!(:user) { create(:user).tap{ |user| user.venues.append(venue) } }
  let!(:reservation) { create :reservation, user: user, court: court }
  let!(:gamepass) { create :game_pass, user: user, venue: venue }
  let!(:invoice) { Invoice.create_for_company(company, user) }
  let!(:custom_invoice_component) { create :custom_invoice_component, invoice: invoice }
  let!(:admin) { create :admin }

  before(:each) do
    company.admins << admin
    ActionMailer::Base.deliveries.clear
    invoice.send!
  end

  describe "POST create" do
    let (:params) do
      {
        company_id: company.id,
        invoice: {
          user_id: user.id,
          custom_invoice_components: [{
                                        name: 'test',
                                        price: 0,
                                        vat_decimal: '0.0'
                                      }]
        }
      }
    end

    subject { post :create, params }

    it 'creates an invoice' do
      expect{ subject }.to change { Invoice.count }.by(1)
      expect(response).to be_success
    end
  end

  describe "POST send_all" do
    let(:params) { { company_id: company.id, selected_ids: [invoice.id]} }
    before { sign_in admin }

    subject { post :send_all, params }

    it_behaves_like "loggable activity", 'invoices_sent'
  end

  describe "POST create_report" do
    before(:each) do
      sign_in admin
      params = { company_id: company.id, report: {from: Date.yesterday, to: Date.current} }
      post :create_report, params
    end

    it "should respond with success 200" do
      expect(response).to be_success
    end

    it "should download excel file" do
      expect(response.header['Content-Type']).to eq('application/xlsx')
    end
  end

  describe "POST mark_paid" do
    before do
      sign_in admin
      params = { company_id: company.id, selected_ids: [invoice.id] }
      post :mark_paid, params
    end

    it "should mark paid selected invoies" do
      expect(flash[:notice]).to be_present
      expect(invoice.reload.is_paid).to be_truthy
      expect(invoice.invoice_components.first.is_paid).to be_truthy
      expect(reservation.reload.is_paid).to be_truthy
      expect(reservation.reload.amount_paid).to eq(reservation.price)
    end
  end

  describe "POST undo_send" do
    before do
      sign_in admin
      params = { company_id: company.id, selected_ids: [invoice.id] }
      post :unsend_all, params
    end

    it "should return invoice to drafts" do
      invoice.reload
      user.reload
      expect(invoice.is_draft).to be_truthy
      expect(user.reservations.drafted.count).to eq(user.reservations.count)
      expect(user.game_passes.drafted.count).to eq(user.game_passes.count)
      expect(flash[:notice]).to be_present
    end
  end

  describe "POST create_drafts" do
    let(:court2) { create :court, venue: venue }
    let!(:reservation_uninvoiced) { create :reservation, user: user, court: court2 }
    let(:start_date) { (Date.current - 1.month).strftime('%d/%m/%Y') }
    let(:end_date) { Date.current.strftime('%d/%m/%Y') }
    let(:params) do
      {
        company_id: company.id,
        user_ids: [user.id],
        save: 'on',
        start_date: start_date,
        end_date: end_date
      }
    end
    before do
      request.env['HTTP_REFERER'] = company_invoices_path(company)
      sign_in admin
    end

    subject { post :create_drafts, params }

    it 'caches dates' do
      expect { subject }.to change { company.reload.cached_invoice_period_start }.from(nil).to(start_date)
                        .and change { company.reload.cached_invoice_period_end }.from(nil).to(end_date)
    end

    it 'caches users when saved is on' do
      subject
      expect(company.reload.saved_invoice_users.first).to eq(user)
    end

    context "for all users of user_type" do
      let(:court3) { create :court, venue: venue }
      let!(:reservation_uninvoiced_2) do
        reservation = create :reservation, court: court3
        venue.users.append(reservation.user)
        reservation
      end
      let(:params) do
        {
          company_id: company.id,
          start_date: start_date,
          end_date: Date.current.advance(months: 2),
          user_type: "all_users"
        }
      end

      it "should create invoice for all users" do
        expect { subject }.to change { Invoice.count }.by(2)
      end
    end
  end
end
