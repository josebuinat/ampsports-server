class ChangeCoachExperience < ActiveRecord::Migration
  def change
    change_table :coaches do |t|
      t.change :experience, :string
    end
  end
end
