class Excel::BaseReport
  attr_reader :filename, :package

  def get_filename(type, from, to)
    "#{type}_Report_#{from.strftime('%d-%m-%Y')}_#{to.strftime('%d-%m-%Y')}.xlsx"
  end

  def set_font_props(package)
    package.workbook.styles.fonts.first.name = 'Calibri'
    package.workbook.styles.fonts.first.sz = 12
  end

  def print_value(sheet, label, value, header_style)
    sheet.add_row([label, value], style: [header_style, nil])
  end

  def to_stream
    raise 'Use #generate to create a report' unless @package
    @package.to_stream
  end

end
