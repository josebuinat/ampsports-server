json.coaches @coaches do |coach|
  json.partial! 'base', coach: coach
end
json.partial! 'shared/pagination', collection: @coaches
