json.array! @templates do |template|
  json.partial! 'admin/venues/game_passes/base', game_pass: template
end
