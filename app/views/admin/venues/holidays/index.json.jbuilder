json.holidays @holidays do |holiday|
  json.partial! 'base', holiday: holiday
end

json.partial! 'shared/pagination', collection: @holidays
