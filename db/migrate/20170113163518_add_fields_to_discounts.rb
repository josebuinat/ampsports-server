class AddFieldsToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :sports, :text
    add_column :discounts, :court_type, :string
    add_column :discounts, :start_date, :date
    add_column :discounts, :end_date, :date
    add_column :discounts, :time_limitations, :text
    add_column :discounts, :surfaces, :text
  end
end
