class CreateParticipationInvoiceComponent < ActiveRecord::Migration
  def change
    create_table :participation_invoice_components do |t|
      t.belongs_to  :invoice, index: true, foreign_key: true
      t.belongs_to  :participation, index: true, foreign_key: true
      t.decimal     :price, precision: 8, scale: 2
      t.boolean     :is_billed, null: false, default: false
      t.boolean     :is_paid, null: false, default: false

      t.timestamps null: false
    end
  end
end
