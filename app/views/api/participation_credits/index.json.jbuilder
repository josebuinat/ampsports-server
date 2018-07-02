json.participation_credits(@participation_credits) do |participation_credit|
  json.partial! 'base', participation_credit: participation_credit
end
