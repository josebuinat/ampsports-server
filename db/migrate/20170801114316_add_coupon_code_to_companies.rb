class AddCouponCodeToCompanies < ActiveRecord::Migration
  def change
    change_table :companies do |t|
      t.string :coupon_code, index: true
    end
  end
end
