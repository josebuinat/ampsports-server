json.users @users do |user|
  json.partial! 'admin/users/base', user: user
  json.outstanding_balance @outstanding_balances[user.id].to_s
end

json.partial! 'shared/pagination', collection: @users
