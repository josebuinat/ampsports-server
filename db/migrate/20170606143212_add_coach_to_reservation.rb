class AddCoachToReservation < ActiveRecord::Migration
  def change
    add_reference :reservations, :coach, index: true
  end
end
