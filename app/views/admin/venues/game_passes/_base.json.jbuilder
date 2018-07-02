json.(game_pass, :id, :total_charges, :remaining_charges, :price, :active, :user_id,
  :venue_id, :created_at, :updated_at, :is_paid, :template_name,
  :court_sports, :court_surfaces, :court_type, :time_limitations, :start_date,
  :end_date, :name, :billing_phase, :coach_ids)

json.coach_names game_pass.coaches.map(&:full_name)

if game_pass.user
  json.user do
    json.partial! 'admin/users/base', user: game_pass.user
  end
end
