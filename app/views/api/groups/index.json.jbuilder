json.groups(@groups) do |group|
  json.partial! 'base', group: group
end
