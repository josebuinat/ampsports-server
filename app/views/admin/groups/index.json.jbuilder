json.groups(@groups) do |group|
  json.partial! 'admin/venues/groups/base', group: group
end

json.partial! 'shared/pagination', collection: @groups
