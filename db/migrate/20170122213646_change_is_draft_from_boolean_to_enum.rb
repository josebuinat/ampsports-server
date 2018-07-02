class ChangeIsDraftFromBooleanToEnum < ActiveRecord::Migration
  def up
    add_column :reservations, :billing_phase, :integer, default: Reservation.billing_phases[:not_billed]
    bool_to_int
    remove_column :reservations, :is_billed, :boolean
  end

  def down
    add_column :reservations, :is_billed, :boolean
    int_to_bool
    remove_column :reservations, :billing_phase, :integer
  end

  private

  def bool_to_int
    not_billed = Reservation.where(is_billed: false).where('id NOT IN (SELECT DISTINCT(reservation_id) FROM invoice_components)')
    say "not billed count: #{not_billed.count}"
    drafted = Reservation.where(is_billed: false).where('id IN (SELECT DISTINCT(reservation_id) FROM invoice_components)')
    say "drafted count: #{drafted.count}"
    billed = Reservation.where(is_billed: true)
    say "billed count: #{billed.count}"
    not_billed.update_all(billing_phase: Reservation.billing_phases[:not_billed]) # :not_billed
    say "not billed phase set..."
    drafted.update_all(billing_phase: Reservation.billing_phases[:drafted]) # :drafted
    say "drafted phase set..."
    billed.update_all(billing_phase: Reservation.billing_phases[:billed]) # :billed
    say "billed phase set..."
  end

  def int_to_bool
    not_billed = Reservation.where(billing_phase: [Reservation.billing_phases[:not_billed],
                                                   Reservation.billing_phases[:drafted]])
    say "not billed count: #{not_billed.count}"
    billed = Reservation.billed # billed
    say "billed count: #{billed.count}"
    not_billed.update_all(is_billed: false)
    say "not billed set..."
    billed.update_all(is_billed: true)
    say "billed set..."
  end
end
