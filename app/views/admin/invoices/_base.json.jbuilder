json.(invoice, :id, :company_id, :is_draft, :created_at, :updated_at,
  :total, :owner_id, :owner_type, :is_paid, :reference_number
)

# billing_time and due_time are nil for draft invoices
json.billing_time invoice.billing_time&.in_time_zone
json.due_time invoice.due_time&.in_time_zone
json.pdf_url company_invoice_url(invoice.company_id, invoice, format: :pdf)

if invoice.owner.is_a?(User)
  json.user do
    json.partial! 'admin/users/base', user: invoice.owner
  end
end

if invoice.owner.is_a?(Coach)
  json.coach do
    json.partial! 'admin/companies/coaches/base', coach: invoice.owner
  end
end
