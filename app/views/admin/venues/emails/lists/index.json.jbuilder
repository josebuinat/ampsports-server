json.lists @lists do |list|
  json.partial! 'base', list: list
end
