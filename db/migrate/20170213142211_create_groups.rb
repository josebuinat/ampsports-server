class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.belongs_to  :venue, index: true, foreign_key: true
      t.belongs_to  :owner, polymorphic: true, index: true
      t.belongs_to  :classification
      t.belongs_to  :coach

      t.string      :name
      t.text        :description
      t.integer     :max_participants
      t.float       :primary_skill_level
      t.text        :accepted_skill_levels
      t.decimal     :participation_price, precision: 8, scale: 2
      t.integer     :priced_duration, default: 0
      t.integer     :cancellation_policy, default: 0

      t.timestamps null: false
    end

    add_column :users, :skill_level, :float
  end
end
