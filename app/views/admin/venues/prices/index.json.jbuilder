json.array! @prices do |price|
  json.partial! 'base', price: price
  json.title number_to_currency(price.price)
end
