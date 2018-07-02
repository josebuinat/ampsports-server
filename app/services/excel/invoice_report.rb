class Excel::InvoiceReport < Excel::BaseReport
  attr_reader :company, :currency, :admin, :tax_name

  def initialize(admin)
    @admin = admin
    @company = admin.company
    @currency = company.currency || I18n.t('number.currency.format.unit')
    @tax_name = admin.company.tax_name
  end

  def generate(from, to)
    invoices = company.invoices.
      includes(:owner).
      where(billing_time: from..to, is_draft: false).
      order(:created_at)

    @filename = get_filename('Invoice', from, to)

    @package = Axlsx::Package.new do |p|
      set_font_props(p)
      header_style = p.workbook.styles.add_style(b: true, alignment: { horizontal: :center })

      p.workbook.add_worksheet(name: 'Sheet1') do |sheet|
        period = [from, to].map{ |t| t.strftime('%d.%m.%Y') }.join(' - ')
        invoices_count = invoices.count

        create_header(sheet, header_style, period, invoices_count)

        invoices.each do |invoice|
          user = invoice.owner
          splitted_vat_values = all_tax_rates.map {|rate| calculate_total_for_tax(invoice, rate) }

          sheet.add_row (
                          [
                            invoice.id,
                            invoice.reference_number,
                            invoice.payment_status,
                            invoice.total,
                            calculate_total_tax(invoice),
                            splitted_vat_values,
                            TimeSanitizer.strftime(invoice.due_date, :date),
                            TimeSanitizer.strftime(invoice.billing_date, :date),
                            user&.full_name,
                            user.try(:email),
                            user.get_billing_address
                          ].flatten
                        )
        end
      end
    end
    self
  end

  private

  def create_header(sheet, header_style, period, invoices_count)
    sheet.add_row([company.company_legal_name], style: header_style)
    sheet.add_row(['Invoice report'], style: header_style)
    sheet.add_row

    print_value(sheet, 'Invoice period', period, header_style)
    print_value(sheet, 'Number of Invoice', invoices_count, header_style)
    printed_on = TimeSanitizer.strftime(Time.current, '%d.%m.%Y at %I.%M%p')
    print_value(sheet, 'Printed on:', printed_on, header_style)
    print_value(sheet, 'By:', admin.full_name, header_style)
    sheet.add_row

    sheet.merge_cells 'E9:L9'
    headings = [
      'Invoice ID',
      'Invoice reference number',
      'Payment Status',
      "Total (#{currency})",
      "#{tax_name} (#{currency})",
      "Amounts by #{tax_name} percentage",
      [''] * (all_tax_rates.length * 2 - 1),
      'Due date',
      'Billing date',
      'Customer name',
      'Email address',
      'Billing address'
    ].flatten
    sheet.add_row(headings, style: header_style)

    sheet.merge_cells 'E10:F10'
    sheet.merge_cells 'G10:H10'
    sheet.merge_cells 'I10:J10'
    sheet.merge_cells 'K10:L10'
    headings_2 = [ [''] * 4, all_tax_rates.map {|rate| ["(#{rate * 100}%) #{tax_name}", ''] } ].flatten
    sheet.add_row(headings_2, style: header_style)

    headings_3 = [ [''] * 4, ["Total amount (#{currency})", "#{tax_name} amount"] * all_tax_rates.length ].flatten
    sheet.add_row(headings_3, style: header_style)

  end

  def calculate_total_tax(invoice)
    invoice.custom_invoice_components.to_a.sum(&:calculate_tax) +
      invoice.gamepass_invoice_components.includes(game_pass: { venue: :company }).to_a.sum(&:calculate_tax) +
      invoice.invoice_components.includes(reservation: { court: { venue: :company }}).to_a.sum(&:calculate_tax)
  end

  # returns Array [Total amount, tax amount] for specific vat decimal
  def calculate_total_for_tax(invoice, tax_rate)
    total_amount = total_tax_amount = 0

    components = invoice.
      all_items.
      flatten.
      select { |component| component.tax_rate == tax_rate }

    components.each do |component|
      total_amount += component.price
      total_tax_amount += component.calculate_tax
    end

    [total_amount, total_tax_amount]
  end

  def all_tax_rates
    if company.country.code == 'us'
      [ company.tax_rate.to_d ]
    else
      CustomInvoiceComponent::DEFAULT_VAT_DECIMALS
    end

  end
end
