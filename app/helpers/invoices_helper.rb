module InvoicesHelper

  # escapes special latex symbols:  # $ % & ~ _ ^ \ { }
  # output should be rendered using raw in erb templates
  def safe_text(text)
    text.to_s.gsub(/[#$%&~_^\\{}]/) do |s|
      if s == "\\"
        "\\textbackslash"
      elsif s == "~"
        "\\textasciitilde"
      elsif s == "^"
        "\\textasciicircum"
      else
        '\\' + s
      end
    end.html_safe
  end

end
