json.partial! 'admin/users/base', user: @user
json.outstanding_balance @company.user_outstanding_balance(@user)
lifetime_balance = @company.user_lifetime_balance(@user)
json.lifetime_value lifetime_balance
reservation_count = @company.reservations.where(user: @user).count
json.average_reservation_fee reservation_count > 0 ? lifetime_balance / reservation_count : 0
if @venue
  json.discounts @user.discounts.for_venue(@venue) do |discount|
    json.partial! 'admin/venues/discounts/base', discount: discount
  end
end

json.is_deletable @user.deletable?(@company)

json.(@user, :phone_number, :zipcode, :city,
  :street_address, :additional_phone_number, :note)
