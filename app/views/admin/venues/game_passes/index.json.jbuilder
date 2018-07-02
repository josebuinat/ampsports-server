json.game_passes @game_passes do |game_pass|
  json.partial! 'base', game_pass: game_pass
end

json.partial! 'shared/pagination', collection: @game_passes
