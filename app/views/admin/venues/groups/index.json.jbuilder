json.groups(@groups) do |group|
  json.partial! 'base', group: group
end

json.partial! 'shared/pagination', collection: @groups
