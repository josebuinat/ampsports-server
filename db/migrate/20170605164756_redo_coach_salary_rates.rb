class RedoCoachSalaryRates < ActiveRecord::Migration
  def change
    remove_column :coach_salary_rates, :start_time, :datetime, null: false
    remove_column :coach_salary_rates, :end_time, :datetime, null: false

    add_column :coach_salary_rates, :start_minute_of_a_day, :integer, null: false, index: true
    add_column :coach_salary_rates, :end_minute_of_a_day, :integer, null: false, index: true
    add_column :coach_salary_rates, :monday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :tuesday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :wednesday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :thursday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :friday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :saturday, :boolean, null: false, default: false
    add_column :coach_salary_rates, :sunday, :boolean, null: false, default: false
  end
end
