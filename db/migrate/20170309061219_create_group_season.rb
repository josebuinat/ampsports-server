class CreateGroupSeason < ActiveRecord::Migration
  def change
    create_table :group_seasons do |t|
      t.belongs_to  :group, index: true, foreign_key: true

      t.date        :start_date
      t.date        :end_date
      t.boolean     :current, default: false

      t.timestamps null: false
    end

    create_table :group_subscriptions do |t|
      t.belongs_to  :user, index: true, foreign_key: true
      t.belongs_to  :group_season, index: true, foreign_key: true

      t.decimal     :price, precision: 8, scale: 2
      t.integer     :billing_phase, default: 0
      t.boolean     :is_paid, default: false
      t.boolean     :cancelled, default: false
      t.boolean     :refunded, default: false
      t.string      :charge_id

      t.timestamps null: false
    end

    create_table :group_subscription_invoice_components do |t|
      t.belongs_to  :invoice, index: true, foreign_key: true
      t.belongs_to  :group_subscription, index: { name: "index_invoice_components_on_group_subscription_id" }, foreign_key: true
      t.decimal     :price, precision: 8, scale: 2
      t.boolean     :is_billed, null: false, default: false
      t.boolean     :is_paid, null: false, default: false

      t.timestamps null: false
    end
  end
end
