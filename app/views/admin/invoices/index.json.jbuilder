json.invoices @invoices do |invoice|
  json.partial! 'base', invoice: invoice
end

json.partial! 'shared/pagination', collection: @invoices

json.summary do
  json.paid_count @company.invoices.paid.count
  json.unpaid_count @company.invoices.unpaid.count
  json.drafts_count @company.invoices.drafts.count
end
