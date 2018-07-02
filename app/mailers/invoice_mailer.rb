class InvoiceMailer < ApplicationMailer
  def invoice_email(user, invoice, from = nil)
    @user = user
    @invoice = invoice
    @company = invoice.company
    @company_legal_name = @company.company_legal_name

    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        mail(
          from: sender_email(from),
          to: @user.email,
          subject: t('.subject', company: @company_legal_name)
        )
      end
    end
  end

  def undo_send_email(user, invoice, from = nil)
    @invoice = invoice
    @user = user
    @company = invoice.company
    @admin = @company.admins.where(level: 3).first
    @company_legal_name = @company.company_legal_name

    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        mail(
          from: sender_email(from),
          to: @user.email,
          subject: t('.subject', company: @company_legal_name)
        )
      end
    end
  end

  private

  def sender_email(from)
    if from.present?
      from
    elsif @company.invoice_sender_email.present?
      @company.invoice_sender_email
    else
      default_params[:from]
    end
  end
end
