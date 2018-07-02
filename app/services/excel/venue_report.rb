class Excel::VenueReport < Excel::BaseReport
  attr_reader :venue, :currency, :tax_name, :admin

  def initialize(admin, venue)
    @admin = admin
    @venue = venue
    @currency = admin.company.currency || I18n.t('number.currency.format.unit')
    @tax_name = admin.company.tax_name
  end

  def generate(from, to)
    reservations = venue.reservations.
      includes(:court, :user).
      between(from, to).
      order(:start_time)

    @filename = get_filename('Sales', from, to)

    @package = Axlsx::Package.new do |p|
      set_font_props(p)
      header_style = p.workbook.styles.add_style(b: true)
      footer_style = p.workbook.styles.add_style(b: true, border: {style: :thin, color: 'FF000000', edges: [:top]})

      p.workbook.add_worksheet(name: 'Chronological') do |sheet|
        sheet.add_row([venue.venue_name], style: header_style)
        sheet.add_row(['Sales report'], style: header_style)
        sheet.add_row

        period = [from, to].map{|t| t.strftime('%d.%m.%Y')}.join(' - ')
        print_value(sheet, 'Period', period, header_style)
        print_value(sheet, 'Printed on:', Time.current.strftime('%d.%m.%Y at %I.%M%p'), header_style)
        print_value(sheet, 'By:', admin.full_name, header_style)

        sheet.add_row

        headings = [
          'Date',
          'Start Time',
          'End Time',
          "Total price (#{currency})",
          "Price without #{tax_name} (#{currency})",
          "#{tax_name} (#{currency})",
          'Code',
          'Customer Name',
          'Customer Email',
          'Customer Phone Number',
          'Payment status',
          "Amount Paid (#{currency})",
          'Payment method (Online/ At the venue/ To be invoiced/ No info)',
          "Outstanding Payment (#{currency})",
          'Notes'
        ]
        sheet.add_row(headings, style: header_style)
        reservations.each do |reservation|
          start_time = TimeSanitizer.output(reservation.start_time)
          end_time = TimeSanitizer.output(reservation.end_time)

          sheet.add_row ([
                            start_time.to_s(:date),
                            start_time.to_s(:time),
                            end_time.to_s(:time),
                            reservation.price,
                            reservation.calculate_price_without_tax,
                            reservation.calculate_tax,
                            reservation.court.sport,
                            reservation.user&.full_name,
                            reservation.user.try(:email), #Guest.last&.email throws NoMethodError
                            reservation.user.try(:phone_number),
                            reservation.payment_type.humanize,
                            reservation.get_amount_paid,
                            reservation.get_payment_method,
                            reservation.outstanding_balance,
                            reservation.note
                          ])
        end
      end

      reservations_per_user = {}
      reservations.each do |reservation|
        user = reservation.for_group? ? reservation.group.owner : reservation.user
        (reservations_per_user[user] ||= []) << reservation
      end

      p.workbook.add_worksheet(name: 'Per Customer') do |sheet|
        user_headings = [
          'First',
          'Last',
          'Email',
          'Customer Phone Number'
        ]
        reservation_headings = [
          'Date',
          "Total Price (#{currency})",
          "Price without #{tax_name} (#{currency})",
          "#{tax_name} (#{currency})",
          'Code',
          "Amount paid (#{currency})",
          'Payment method (Online/ At the venue/ To be invoiced/ No info)',
          "Outstanding balance (#{currency})",
          'Recurring reservation (yes/no)',
          'Notes'
        ]
        reservations_per_user.each do |user, user_reservations|
          2.times { sheet.add_row }
          sheet.add_row user_headings, style: header_style
          user_row = [ :first_name, :full_name, :last_name, :email, :phone_number ].map { |attr| user.try(attr) }
          user_row = [ user_row[0] || user_row[1], *user_row.last(3) ]
          sheet.add_row user_row

          offset = [nil] * user_headings.size
          sheet.add_row offset + reservation_headings, style: header_style

          user_payments = OpenStruct.new(total_price: 0, amount_paid: 0)
          user_reservations.each do |reservation|
            start_time = TimeSanitizer.output(reservation.start_time)
            sheet.add_row (
                             offset +
                               [
                                 start_time.to_s(:date),
                                 reservation.price,
                                 reservation.calculate_price_without_tax,
                                 reservation.calculate_tax,
                                 reservation.court.sport,
                                 reservation.get_amount_paid,
                                 reservation.get_payment_method,
                                 reservation.outstanding_balance,
                                 reservation.membership? ? 'Yes' : 'No',
                                 reservation.note
                               ]
                           )

            user_payments.total_price += reservation.price
            user_payments.amount_paid += reservation.get_amount_paid
          end

          values = [
            'TOTAL',
            user_payments.total_price,
            *[nil]*3,
            user_payments.amount_paid,
            nil,
            user_payments.total_price - user_payments.amount_paid
          ]
          sheet.add_row(offset + values, style: [nil] * offset.length + [footer_style] * values.size)
        end
      end
    end
    self
  end
end
