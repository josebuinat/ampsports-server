json.group_custom_billers(@group_custom_billers) do |group_custom_biller|
  json.partial! 'base', group_custom_biller: group_custom_biller
end

json.partial! 'shared/pagination', collection: @group_custom_billers
