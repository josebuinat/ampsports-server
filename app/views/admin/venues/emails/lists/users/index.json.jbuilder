json.users @users do |user|
  json.partial! 'admin/users/base', user: user
  json.email_subscription user[:email_subscription]
end

json.partial! 'shared/pagination', collection: @users
