json.(subscription, :id, :is_paid, :billing_phase, :start_date, :end_date, :current,
                    :price, :amount_paid, :created_at, :updated_at)
json.group_id subscription.group.id
json.payable subscription.payable?
json.cancelable subscription.cancelable?
json.user do
  json.partial! 'admin/users/base', user: subscription.user
end
