class CreateReservationsUsers < ActiveRecord::Migration
  def change
    create_table :reservations_users, id: false do |t|
      t.belongs_to :user, index: true, foreign_key: true, null: false
      t.belongs_to :reservation, index: true, foreign_key: true, null: false
    end
  end
end
