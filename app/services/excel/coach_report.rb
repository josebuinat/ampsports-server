class Excel::CoachReport < Excel::BaseReport
  attr_reader :company, :currency, :admin, :coach, :venue

  def initialize(coach, admin, venue)
    @coach = coach
    @admin = admin
    @venue = venue
    @company = coach.company
    @currency = company.currency_unit
  end

  def generate(sport:, start_date:, end_date:)
    calculator = Coach::Reports::SalaryCalculator.new(coach, venue, start_date: start_date,
                                                                      end_date: end_date,
                                                                      sport: sport)
    reservations = calculator.reservations.includes(:court, :classification).to_a
    start_date = TimeSanitizer.input(start_date)
    end_date = TimeSanitizer.input(end_date)

    @filename = get_filename('Coach', start_date, end_date)

    @package = Axlsx::Package.new do |p|
      set_font_props(p)
      header_style = p.workbook.styles.add_style(b: true, alignment: { horizontal: :center })
      footer_style = p.workbook.styles.add_style(b: true, border: { style: :thin,
                                                                    color: 'FF000000',
                                                                    edges: [:top] })

      p.workbook.add_worksheet(name: t('reservations')) do |sheet|
        period = "#{start_date.to_s(:date)} - #{end_date.to_s(:date)}"
        reservations_count = reservations.count
        sport_name = Court.human_attribute_name("sport_name.#{sport}")
        total_coach_salary = 0.to_d

        create_header(sheet, header_style, period, sport_name, reservations_count)

        reservations.each do |reservation|
          start_time = TimeSanitizer.output(reservation.start_time)
          end_time = TimeSanitizer.output(reservation.end_time)
          coach_salary = reservation.coach_salary(coach)
          total_coach_salary += coach_salary

          sheet.add_row ([
            start_time.to_s(:date),
            start_time.to_s(:user_clock_time),
            end_time.to_s(:user_clock_time),
            reservation.court.court_name,
            reservation.for_group? ? reservation.group.name : nil,
            reservation.classification&.name,
            reservation.hours,
            reservation.price,
            coach_salary,
            reservation.payment_type.humanize,
            reservation.note
          ])
        end

        sheet.add_row([
          t('total'),
          *[nil]*5,
          reservations.sum(&:hours),
          reservations.sum(&:price),
          total_coach_salary,
          *[nil]*2,
        ], style: footer_style)
      end
    end
    self
  end

  private

  def t(name, params = {})
    I18n.t("coaches.reports.#{name}", **params)
  end

  def create_header(sheet, header_style, period, sport, reservations_count)
    sheet.add_row([company.company_legal_name], style: header_style)
    sheet.add_row([t('coach_report')], style: header_style)
    sheet.add_row

    print_value(sheet, t('sport_name'), sport, header_style)
    print_value(sheet, t('report_period'), period, header_style)
    print_value(sheet, t('number_of_bookings'), reservations_count, header_style)
    printed_on = Time.current.to_s(:user_clock_date_time)
    print_value(sheet, t('printed_on'), printed_on, header_style)
    print_value(sheet, t('by'), admin.full_name, header_style)
    sheet.add_row

    headings = [
      t('date'),
      t('start_time'),
      t('end_time'),
      t('court'),
      t('group_name'),
      t('classification'),
      t('hours'),
      t('revenue', currency: currency),
      t('salary', currency: currency),
      t('payment_status'),
      t('notes')
    ]
    sheet.add_row(headings, style: header_style)
  end
end
