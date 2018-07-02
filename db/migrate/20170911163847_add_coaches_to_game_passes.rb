class AddCoachesToGamePasses < ActiveRecord::Migration
  def change
    create_table :game_pass_coach_connections do |t|
      t.belongs_to  :game_pass, index: true, null: false
      t.belongs_to  :coach, index: true, null: false

      t.timestamps null: false
    end
  end
end
