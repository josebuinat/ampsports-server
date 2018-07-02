class CustomInvoiceComponent < ActiveRecord::Base
  include Taxable
  DEFAULT_VAT_DECIMALS = [BigDecimal.new('0'),
                          BigDecimal.new('0.10'),
                          BigDecimal.new('0.14'),
                          BigDecimal.new('0.24')].freeze

  belongs_to :invoice
  has_one :credit, as: :creditable, dependent: :destroy

  validates :price, :name, :vat_decimal, presence: true

  # overriden Taxable method
  def tax_rate
    vat_decimal
  end

  def vat_to_s
    "#{vat_decimal * 100}%"
  end

  def bill!
    self.update_attribute(:is_billed, true)
  end

  def mark_paid!
    self.update_attribute(:is_paid, true)
  end

  def charged!
    self.update_attributes(is_billed: true, is_paid: true)
  end
end
