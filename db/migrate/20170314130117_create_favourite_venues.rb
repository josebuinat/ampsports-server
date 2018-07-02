class CreateFavouriteVenues < ActiveRecord::Migration
  def change
    create_table :favourite_venues do |t|
      t.references :user, index: true, foreign_key: true
      t.references :venue, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
