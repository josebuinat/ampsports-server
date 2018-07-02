json.partial! 'base', invoice: @invoice

json.custom_invoice_components @invoice.custom_invoice_components do |custom_component|
  json.(custom_component, :id, :invoice_id, :price, :is_billed, :is_paid,
    :name, :vat_decimal, :created_at, :updated_at)
end

json.gamepass_invoice_components @invoice.gamepass_invoice_components do |gamepass_component|
  json.(gamepass_component, :id, :invoice_id, :price, :is_billed, :is_paid)
  json.auto_name gamepass_component.game_pass.auto_name
  json.price_with_currency number_to_currency(gamepass_component.price)
end

json.invoice_components @invoice.invoice_components do |invoice_component|
  json.is_canceled invoice_component.reservation.blank?
  json.(invoice_component, :id, :invoice_id, :court_name, :price, :is_billed, :is_paid)
  json.start_time TimeSanitizer.output(invoice_component.start_time)
  json.end_time TimeSanitizer.output(invoice_component.end_time)
  json.coach_name invoice_component.coaches.map(&:full_name).join(', ')
end

json.participation_invoice_components(@invoice.participation_invoice_components) do
    |participation_invoice_component|
  json.(participation_invoice_component, :id, :invoice_id, :is_billed, :is_paid, :price,
                                         :court_name, :group_name)
  json.start_time TimeSanitizer.output(participation_invoice_component.start_time)
  json.end_time TimeSanitizer.output(participation_invoice_component.end_time)
  json.coach_name participation_invoice_component.coaches.map(&:full_name).join(', ')
end

json.group_subscription_invoice_components(@invoice.group_subscription_invoice_components) do
    |group_subscription_component|
  json.(group_subscription_component, :id, :invoice_id, :is_billed, :is_paid, :price, :group_name)
  json.start_date TimeSanitizer.output(group_subscription_component.start_date).to_date
  json.end_date TimeSanitizer.output(group_subscription_component.end_date).to_date
end
