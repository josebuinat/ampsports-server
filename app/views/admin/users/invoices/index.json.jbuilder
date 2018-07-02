json.invoices @invoices do |invoice|
  json.partial! 'base', invoice: invoice
end
