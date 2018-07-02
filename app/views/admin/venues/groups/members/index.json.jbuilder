json.members(@members) do |member|
  json.partial! 'base', member: member
end

json.partial! 'shared/pagination', collection: @members
