class SavedInvoiceUserConnection < ActiveRecord::Base
  belongs_to :user
  belongs_to :company

  enum connection_types: [:recent, :saved]
end
