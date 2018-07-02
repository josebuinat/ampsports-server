class AddDateIndexOnReservations < ActiveRecord::Migration
  def up
    execute "CREATE INDEX index_reservations_start_time_date ON reservations ((start_time::DATE))"
  end

  def down
    execute "DROP INDEX index_reservations_start_time_date"
  end
end
