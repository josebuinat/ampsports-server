json.customers(@customers) do |customer|
  json.(customer, :id, :first_name, :last_name, :email, :phone_number, :city, :street_address, :zipcode, :profile_picture)
  json.outstanding_balance @outstanding_balances[customer.id].to_f
  json.reservations_done @reservations[customer.id].try(:count).to_i
end

json.current_page @customers.current_page
json.total_pages @customers.total_pages
