class CreateGroupCustomBiller < ActiveRecord::Migration
  def change
    create_table :group_custom_billers do |t|
      t.string  :company_legal_name
      t.string  :company_business_type
      t.string  :company_tax_id
      t.string  :bank_name
      t.string  :company_iban
      t.string  :company_bic
      t.string  :company_country
      t.string  :company_street_address
      t.string  :company_zip
      t.string  :company_city
      t.string  :company_phone
      t.string  :company_website
      t.string  :invoice_sender_email
      t.decimal :tax_rate, precision: 5, scale: 4, null: false, default: 0
      t.integer :country_id, null: false, default: 1

      t.timestamps null: false
    end

    add_reference :groups, :custom_biller, index: true
    add_reference :invoices, :group_custom_biller, index: true
  end
end
