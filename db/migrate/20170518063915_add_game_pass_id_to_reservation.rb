class AddGamePassIdToReservation < ActiveRecord::Migration
  def change
    add_reference :reservations, :game_pass, index: true
  end
end
