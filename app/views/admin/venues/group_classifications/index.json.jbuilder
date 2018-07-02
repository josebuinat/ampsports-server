json.group_classifications(@group_classifications) do |group_classification|
  json.partial! 'base', group_classification: group_classification
end

json.partial! 'shared/pagination', collection: @group_classifications
