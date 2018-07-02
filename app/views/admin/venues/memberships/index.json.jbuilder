json.memberships @memberships do |membership|
  json.partial! 'base', membership: membership
end

json.partial! 'shared/pagination', collection: @memberships
