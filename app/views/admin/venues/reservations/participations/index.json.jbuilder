json.participations @participations do |participation|
  json.partial! 'base', participation: participation
end

json.partial! 'shared/pagination', collection: @participations
