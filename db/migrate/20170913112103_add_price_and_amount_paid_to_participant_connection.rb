class AddPriceAndAmountPaidToParticipantConnection < ActiveRecord::Migration
  def change
    add_column :reservation_participant_connections, :price, :decimal, default: 0, null: false
    add_column :reservation_participant_connections, :amount_paid, :decimal, default: 0, null: false
  end
end
