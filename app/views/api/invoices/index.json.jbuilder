json.invoices(@invoices) do |invoice|
  @current_company = invoice.company
  json.id invoice.id
  json.total number_to_currency(invoice.total)
  json.isPaid invoice.is_paid
  json.referenceNumber invoice.reference_number
  json.billingTime invoice.billing_time.strftime('%d/%m/%Y')
  json.dueTime invoice.due_time.strftime('%d/%m/%Y')
  json.url api_invoice_url(invoice, format: :pdf)
  json.components(invoice.invoice_components) do |ic|
      json.partial! 'api/reservations/reservation', reservation: ic.reservation
  end
  json.customComponents(invoice.custom_invoice_components) do |cic|
      json.extract! cic, :id, :name, :is_billed, :is_paid
      json.price number_to_currency(cic.price)
  end
  json.gamepassComponents(invoice.gamepass_invoice_components) do |gic|
      json.extract! gic, :id, :is_billed, :is_paid
      json.price number_to_currency(gic.price)
  end
  json.participationComponents(invoice.participation_invoice_components) do |pic|
      json.partial! 'api/reservations/reservation', reservation: pic.reservation
  end
  json.groupSubscriptionComponents(invoice.group_subscription_invoice_components) do |gsic|
      json.extract! gsic, :id, :is_billed, :is_paid
      json.price number_to_currency(gsic.price)
      json.groupName gsic.group.name
      json.startDate gsic.start_date.to_s(:date)
      json.endDate gsic.end_date.to_s(:date)
  end
  json.company do
    json.partial! 'api/companies/company', company: invoice.company
  end
end
