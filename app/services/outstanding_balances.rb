class OutstandingBalances
  def initialize(company, custom_biller = nil)
    @company = company
    @custom_biller = custom_biller
  end

  def all_users
    @all_users ||= @company.users.where(id: users_with_balance_ids)
  end

  def all_coaches
    @all_coaches ||= @company.coaches.where(id: coach_with_balance_ids)
  end

  def saved_users
    @company.saved_invoice_users
  end

  def recent_users
    @company.recent_invoice_users
  end

  def membership_users
     User.where(id: @company.memberships_users.pluck(:id) & users_with_balance_ids)
  end

  def users_by_type(user_type)
    case user_type
    when "membership_users"
      membership_users
    when "saved_users"
      saved_users
    when "recent_users"
      recent_users
    when "all_users"
      all_users
    when "all_coaches"
      all_coaches
    else
      # we will not raise exception, but return nothing
      User.none
    end
  end

  def outstanding_balances
    @outstanding_balances ||= @company.outstanding_balances(@custom_biller)
  end

  def coach_outstanding_balances
    @coach_outstanding_balances ||= @company.coach_outstanding_balances
  end

  def users_with_balance_ids
    @users_with_balance_ids ||= outstanding_balances.select {|id, balance| balance > 0.0 }
                                                    .keys
  end

  def coach_with_balance_ids
    @coach_with_balance_ids ||= coach_outstanding_balances.
                                  select {|id, balance| balance > 0.0 }
                                  .keys
  end
end
