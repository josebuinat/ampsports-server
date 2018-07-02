module Taxable
  extend ActiveSupport::Concern

  def calculate_tax
    price - calculate_price_without_tax
  end

  def calculate_price_without_tax
    ((price / (1 + tax_rate)) * 100).ceil.to_f / 100
  end

  def tax_rate
    company&.tax_rate || 0
  end
end
