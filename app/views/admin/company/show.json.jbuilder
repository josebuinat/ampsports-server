json.partial! 'base', company: @company
if @auth_payload.present?
  json.auth_payload @auth_payload
end
