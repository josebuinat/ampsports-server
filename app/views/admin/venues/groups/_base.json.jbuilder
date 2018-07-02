json.(group, :id, :coach_ids, :name, :max_participants, :skill_levels, :priced_duration,
             :cancellation_policy, :created_at, :updated_at, :classification_id, :description,
             :participation_price, :owner_name, :owner_type)
json.owner_id (group.admin_owned? ? nil : group.owner_id)
json.members_count group.members.count

json.seasons(group.seasons) do |season|
  json.(season, :id, :start_date, :end_date, :current, :participation_price, :created_at, :updated_at)
end

json.owner do
  if group.admin_owned?
    json.partial! 'admin/companies/admins/base', admin: group.owner
  else
    json.partial! 'admin/users/base', user: group.owner
  end
end

json.coaches(group.coaches) do |coach|
  json.partial! 'admin/companies/coaches/base', coach: coach
end
