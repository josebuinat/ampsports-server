# When creating a company user can specify a coupon code.
class Coupon < ActiveRecord::Base
  validates :code, presence: true, uniqueness: { case_sensetive: false }

  def code=(value)
    super value&.downcase
  end
end