class GroupCustomBiller < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :country

  has_many :groups, foreign_key: :custom_biller_id, dependent: :nullify
  has_many :invoices, dependent: :nullify

  validates :groups, :company_legal_name, :company_business_type, :company_tax_id,
            :bank_name, :company_iban, :company_bic, :company_street_address,
            :company_zip, :company_city, :company_phone, :invoice_sender_email,
            :tax_rate,
            presence: true
end
