json.users @users do |user|
  json.partial! 'base', user: user
  json.outstanding_balance @outstanding_balances[user.id]
  json.lifetime_value @lifetime_values[user.id]
  if @venue
    json.discounts user.discounts.for_venue(@venue) do |discount|
      json.partial! 'admin/venues/discounts/base', discount: discount
    end
  end
end

json.partial! 'shared/pagination', collection: @users
