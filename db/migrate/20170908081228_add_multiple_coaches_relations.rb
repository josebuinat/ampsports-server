class AddMultipleCoachesRelations < ActiveRecord::Migration
  def change
    create_table :group_coach_connections do |t|
      t.belongs_to  :group, index: true, null: false
      t.belongs_to  :coach, index: true, null: false

      t.timestamps null: false
    end

    create_table :reservation_coach_connections do |t|
      t.belongs_to  :reservation, index: true, null: false
      t.belongs_to  :coach, index: true, null: false
      t.decimal     :salary, precision: 8, scale: 2
      t.boolean     :salary_paid, null: false, default: false

      t.timestamps null: false
    end
  end
end
