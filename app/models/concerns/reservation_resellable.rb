module ReservationResellable
  extend ActiveSupport::Concern

  included do
    scope :reselling, -> { where(reselling: true) }
    scope :not_reselling, -> { where(reselling: false) }

    after_update :add_credit_to_initial_owner, if: :resold_was_paid?
    after_save   :disconnect_from_membership, if: :was_resold?
    validate     :not_resell_what_is_resold, on: :update
  end

  def resold?
    initial_membership_id.present?
  end

  def resellable?
    end_time > Time.current.utc && recurring? && !resold? && !for_group?
  end

  def find_matching_resell
    resell_scope = Reservation.reselling.where(court: court)

    if venue.allow_overlapping_resell
      resell_scope = resell_scope.overlapping(start_time.utc, end_time.utc)
    else
      resell_scope = resell_scope.where(start_time: start_time.utc, end_time: end_time.utc)
    end

    resell_scope.take
  end

  # finds reselling reservation with matching time/court
  # assigns to user and converts into normal reservation
  # resets payment status
  # makes it reversible by initial_membership_id
  # generally used as @rsrv = Reservation.new(params).take_matching_resell
  def take_matching_resell
    return self unless court.present? && start_time.present? && end_time.present?

    resell = find_matching_resell

    if resell && resell.resellable?
      resell.assign_attributes(base_resold_attributes.merge(
                                price: price,
                                start_time: start_time,
                                end_time: end_time,
                                user: user,
                                initial_membership_id: resell.membership.id,
                                game_pass_id: game_pass_id
                              ))
      resell
    else
      self
    end
  end

  # assigns reselling recurring reservation to new user and convert into normal reservation
  # resets payment status
  # makes it reversible by initial_membership_id
  def resell_to_user(new_owner, as_admin = false)
    errors.add :base, 'must be reselling' unless reselling?
    errors.add :base, 'must be recurring' unless recurring?
    errors.add :base, 'already resold' if resold?
    new_owner_has_valid_type = new_owner.is_a?(User) || new_owner.is_a?(Guest)
    errors.add :base, 'must be resold to User or Guest' unless new_owner_has_valid_type
    errors.add :base, 'cannot be resold to a same user as before' if new_owner == user

    return false if errors.any?

    new_attributes = base_resold_attributes.merge(
      user: new_owner,
      initial_membership_id: membership.id
    )
    new_attributes[:update_by_admin] = true if as_admin

    update_attributes(new_attributes).tap do |success|
      booking_mail if success
    end
  end

  # used instead of cancellation for resold reservations
  # converts reservation back to reselling recurring resevation
  # restores price and payment status
  # returns to initial owner and membership
  # withdraws credit if it was created on resell
  def pass_back_to_initial_owner
    initial_membership = Membership.find(initial_membership_id)
    initial_invoice_component = invoice_components.user(initial_membership.user).take
    was_billed = initial_invoice_component&.is_billed.present?
    was_paid = initial_invoice_component&.is_paid.present?

    update_attributes(  price: initial_membership.price,
                        booking_type: self.class.booking_types[:membership],
                        reselling: true,
                        billing_phase: self.class.billing_phases[was_billed ? :billed : :not_billed],
                        is_paid: was_paid,
                        payment_type: self.class.payment_types[was_paid ? :paid : :unpaid],
                        amount_paid: was_paid ? initial_membership.price : 0,
                        game_pass_id: nil,
                        user: initial_membership.user,
                        initial_membership_id: nil,
                        membership: initial_membership,
                        refunded: false)
    # resell can change timings, if it is allowed by venue, try to restore them
    restore_timings_from_membership(initial_membership)
    withdraw_credit

    self
  end

  private

  def not_resell_what_is_resold
    if reselling? && resold?
      errors.add :reselling, 'cannot be changed for resold reservations'
    end
  end

  def restore_timings_from_membership(initial_membership)
    membership_start_time_params = {
      hour: initial_membership.start_time.hour,
      minute: initial_membership.start_time.min
    }
    membership_end_time_params = {
      hour: initial_membership.end_time.hour,
      minute: initial_membership.end_time.min
    }

    update_attributes(
      start_time: start_time.change(membership_start_time_params),
      end_time: end_time.change(membership_end_time_params)
    )
  end

  def base_resold_attributes
    {
      booking_type: self.class.booking_types[:online],
      reselling: false,
      billing_phase: self.class.billing_phases[:not_billed],
      is_paid: false,
      payment_type: self.class.payment_types[:unpaid],
      amount_paid: 0,
    }
  end

  def was_resold?
    initial_membership_id_changed? && resold?
  end

  def was_paid?
    # this is not pretty and can lead to double execution in some cases
    # we should get rid of payment status duplicaton
    (is_paid_changed? && is_paid) || (payment_type_changed? && paid?)
  end

  def resold_was_paid?
    resold? && was_paid?
  end

  def disconnect_from_membership
    membership_connector.delete if membership_connector.present?
  end

  # if reservation was already invoiced to initial owner
  def add_credit_to_initial_owner
    initial_owner = Membership.find_by_id(initial_membership_id)&.user
    return unless initial_owner.present?

    initial_invoice_component = invoice_components.user(initial_owner).take
    initial_invoice = initial_invoice_component&.invoice
    return unless initial_invoice.present?

    # should fail payment if can't return money to initial owner
    Credit.create!(
      user: initial_owner,
      company: company,
      balance: initial_invoice_component.price,
      creditable: self
    )
  end

  def withdraw_credit
    credit = Credit.find_by(creditable: self)
    credit.destroy if credit.present?
  end
end
