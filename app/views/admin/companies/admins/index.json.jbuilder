json.admins @admins do |admin|
  json.partial! 'base', admin: admin
end
json.partial! 'shared/pagination', collection: @admins
