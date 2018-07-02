require 'rails_helper'

describe InvoiceMailer do
  describe 'invoice_email' do
    let(:invoice) { create :invoice }
    let(:user) { invoice.owner }
    let(:company) { invoice.company }
    let(:mail) { described_class.invoice_email(user, invoice).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eql I18n.t('.invoice_mailer.invoice_email.subject',
                                    company: company.company_legal_name,
                                    locale: user.locale)
    end

    it 'sets correct "to"' do
      expect(mail.to).to eql [user.email]
    end

    it 'sets correct "from"' do
      expect(mail.from).to eql ['no-reply@playven.com']
    end
  end

  describe 'undo_send_email' do
    let(:invoice) { create :invoice }
    let(:user) { invoice.owner }
    let(:company) { invoice.company }
    let!(:admin) { create :admin, company: company, email: 'admin@company.com' }
    let(:mail) { described_class.undo_send_email(user, invoice).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eql I18n.t('.invoice_mailer.undo_send_email.subject',
                                    company: company.company_legal_name,
                                    locale: user.locale)
    end

    it 'sets correct "to"' do
      expect(mail.to).to eql [user.email]
    end

    it 'sets correct "from"' do
      expect(mail.from).to eql ['no-reply@playven.com']
    end

    it 'renders admin email' do
      expect(mail.body.encoded).to match admin.email
    end
  end
end
