json.price_rates @price_rates do |price_rate|
  json.partial! 'base', price_rate: price_rate
end
