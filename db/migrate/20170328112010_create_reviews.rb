class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.text :text
      t.float :rating, null: false
      t.belongs_to :author, index: true
      t.belongs_to :venue, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
