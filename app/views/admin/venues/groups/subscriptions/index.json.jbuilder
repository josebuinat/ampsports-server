json.subscriptions(@subscriptions) do |subscription|
  json.partial! 'base', subscription: subscription
end

json.partial! 'shared/pagination', collection: @subscriptions
