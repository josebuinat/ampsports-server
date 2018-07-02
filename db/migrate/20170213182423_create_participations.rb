class CreateParticipations < ActiveRecord::Migration
  def change
    create_table :participations do |t|
      t.belongs_to  :user, index: true, foreign_key: true
      t.belongs_to  :reservation, index: true, foreign_key: true

      t.decimal     :price, precision: 8, scale: 2
      t.integer     :billing_phase, default: 0
      t.boolean     :is_paid, default: false
      t.boolean     :cancelled, default: false
      t.boolean     :refunded, default: false
      t.string      :charge_id

      t.timestamps null: false
    end

    change_table :reservations do |t|
      t.integer :participations_count, default: 0
    end
  end
end
