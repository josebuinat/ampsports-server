class RenameReservationsUsersToReservationParticipantConnections < ActiveRecord::Migration
  def change
    rename_table :reservations_users, :reservation_participant_connections
    add_column :reservation_participant_connections, :id, :primary_key
  end
end
