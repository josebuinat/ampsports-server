json.(member, :id, :group_id, :created_at, :updated_at)
json.user do
  json.partial! 'admin/users/base', user: member.user
end