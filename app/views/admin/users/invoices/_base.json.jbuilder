json.(invoice, :id, :company_id, :is_draft, :created_at, :updated_at,
  :total, :owner_id, :owner_type, :is_paid, :reference_number
)
json.due_time invoice.due_time&.in_time_zone
json.pdf_url company_invoice_url(invoice.company_id, invoice, format: :pdf)
