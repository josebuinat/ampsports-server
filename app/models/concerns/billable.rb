module Billable
  extend ActiveSupport::Concern

  included do
    after_create :draft
    before_destroy :undraft

    ## Should be defined in the models!
    def product
      nil
    end

    def self.without_undraft_callback
      skip_callback :destroy, :before, :undraft

      yield

      set_callback :destroy, :before, :undraft
    end

    def bill!
      Invoice.transaction do
        product.update_attribute(:billing_phase, :billed) if update_product?
        update_attribute(:is_billed, true)
      end
    end

    def unbill!
      Invoice.transaction do
        product.update_attribute(:billing_phase, :drafted) if update_product?
        update_attribute(:is_billed, false)
      end
    end

    def mark_paid!
      Invoice.transaction do
        product.update_attribute(:is_paid, true) if update_product?
        update_attribute(:is_paid, true)
      end
    end

    def charged!
      update_attributes(is_billed: true, is_paid: true)
    end

    def update_product?
      product.present?
    end

    private

    def draft
      product.update_attribute(:billing_phase, :drafted) if update_product?
    end

    def undraft
      product.update_attribute(:billing_phase, :not_billed) if update_product?
    end
  end
end
