class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.timestamps
    end
  end
end
