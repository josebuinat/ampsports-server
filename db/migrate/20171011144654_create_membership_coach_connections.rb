class CreateMembershipCoachConnections < ActiveRecord::Migration
  def change
    create_table :membership_coach_connections do |t|
      t.belongs_to :coach, index: true, foreign_key: true
      t.belongs_to :membership, index: true, foreign_key: true

      t.timestamps
    end
  end
end
