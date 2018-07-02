json.discounts @discounts do |discount|
  json.partial! 'base', discount: discount
end

json.partial! 'shared/pagination', collection: @discounts
