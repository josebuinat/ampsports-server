class AddCoachSalaryToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :coach_salary, :decimal, precision: 8, scale: 2
    add_column :reservations, :coach_salary_paid, :boolean, null: false, default: false
  end
end
