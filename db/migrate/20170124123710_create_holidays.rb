class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps null: false
    end

    create_table :courts_holidays do |t|
      t.belongs_to :holiday, index: true
      t.belongs_to :court, index: true
    end

    add_foreign_key :courts_holidays, :courts
    add_foreign_key :courts_holidays, :holidays
  end
end
