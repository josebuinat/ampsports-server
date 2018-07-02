class AddClassificationToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :classification_id, :integer, index: true
    add_foreign_key :reservations, :group_classifications, column: :classification_id
  end
end
