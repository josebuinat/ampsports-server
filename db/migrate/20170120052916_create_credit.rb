class CreateCredit < ActiveRecord::Migration
  def change
    create_table :credits do |t|
      t.belongs_to  :user, index: true, foreign_key: true
      t.belongs_to  :company, index: true, foreign_key: true
      t.references  :creditable, polymorphic: true, index: true
      t.decimal     :balance, precision: 8, scale: 2

      t.timestamps null: false
    end
  end
end
