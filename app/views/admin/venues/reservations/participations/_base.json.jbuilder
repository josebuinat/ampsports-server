json.(participation, :id, :is_paid, :billing_phase, :price, :created_at, :updated_at)
json.user do
  json.partial! 'admin/users/base', user: participation.user
end
