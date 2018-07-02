class CreateCoachSalaryRates < ActiveRecord::Migration
  def change
    create_table :coach_salary_rates do |t|
      t.belongs_to :coach, index: true, foreign_key: true
      t.belongs_to :venue, index: true, foreign_key: true
      t.integer    :sport_name, null: false
      t.datetime       :start_time, null: false
      t.datetime       :end_time, null: false

      t.decimal    :rate, precision: 8, scale: 2

      t.string     :created_by
      t.timestamps null: false
    end
  end
end
