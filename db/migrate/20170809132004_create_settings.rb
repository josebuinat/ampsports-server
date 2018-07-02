class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.belongs_to  :owner, polymorphic: true, index: true, null: false

      t.string      :name, index: true, null: false
      t.string      :value, null: false

      t.timestamps null: false
    end
  end
end
