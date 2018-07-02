class CreateGroupClassifications < ActiveRecord::Migration
  def change
    create_table :group_classifications do |t|
      t.belongs_to  :venue, index: true, foreign_key: true
      t.string      :name

      t.timestamps null: false
    end

    create_table :group_classifications_connectors do |t|
      t.belongs_to  :group_classification, foreign_key: true, index: { name: "index_groups_classifications_on_classification_id" }
      t.belongs_to  :group, foreign_key: true, index: { name: "index_groups_classifications_on_group_id" }
    end
  end
end
