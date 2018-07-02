class GamepassInvoiceComponent < ActiveRecord::Base
  include Taxable
  include Billable

  belongs_to :invoice
  belongs_to :game_pass
  has_one :company, through: :invoice
  has_one :user, through: :game_pass

  # define product for Billable
  alias product game_pass

  def self.build_from(game_passes)
    game_passes.map do |game_pass|
      new(
        game_pass: game_pass,
        price: game_pass.price
      )
    end
  end
end
