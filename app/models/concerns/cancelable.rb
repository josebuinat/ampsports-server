module Cancelable
  extend ActiveSupport::Concern

  def cancel(actor, skip_refund = false)
    cancel_helper(actor, skip_refund)

    if resold?
      pass_back_to_initial_owner
    else
      update_attribute(:inactive, true)
    end
  end

  def cancelable?
    ((start_time - Time.current.utc) / 1.hour) > court.venue.cancellation_time
  end

  def refundable?
    cancelable? && refundable_by_admin?
  end

  def refundable_by_admin?
    (charge_id.present? || game_pass_id.present?) && !refunded
  end

  def cancellation_email(actor)
    return if actor.nil? || actor.is_a?(Reservation)

    method = if actor.is_a? Admin
      :admin_cancellation_email
    else
      :user_cancellation_email
    end

    collect_everyone_related_to_this_reservation.each do |recipient|
      CancellationMailer.public_send(method, recipient, self,
        override_should_send_emails: override_should_send_emails).deliver_later!
    end

  end

  # refund without reverse_transfer option takes the money from our
  # account. Create the refund explicitly with amount and reverse_transfer
  def stripe_refund
    return unless charge_id.present?
    Reservation.transaction do
      charge = Stripe::Charge.retrieve(charge_id)
      charge.refunds.create(amount: charge.amount, reverse_transfer: true)
      update_attributes(refunded: true, is_paid: false, billing_phase: :not_billed, charge_id: nil)
    end
  rescue Exception => e
    custom_params = { reservation_id: id, charge_id: charge_id, amount: charge.amount }
    Rollbar.error(e, 'Stripe refund failed', custom_params)
  end

  def game_pass_refund
    return unless game_pass.present?

    Reservation.transaction do
      game_pass.restore_charges!(hours)
      update_attributes(refunded: true, is_paid: false, billing_phase: :not_billed, game_pass_id: nil)
    end
  rescue StandardError => e
    custom_params = { reservation_id: id, game_pass_id: game_pass_id, charges: hours }
    Rollbar.error(e, 'Game pass refund failed', custom_params)
  end

  private

  def cancel_helper(actor, skip_refund)
    unless skip_refund || refunded
      stripe_refund
      game_pass_refund
    end

    return if user.blank?

    if actor.is_a? Admin
      SegmentAnalytics.admin_cancellation(self, actor)
    elsif actor.is_a?(User) || actor.is_a?(Guest)
      SegmentAnalytics.user_cancellation(self, actor)
    elsif actor.nil?
      SegmentAnalytics.cancellation_due_to_other_reservation(self, actor)
    else
      SegmentAnalytics.unknown_cancellation(self, actor)
    end
    cancellation_email(actor)
  end
end
