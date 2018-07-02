class Review < ActiveRecord::Base
  belongs_to :venue
  belongs_to :author, class_name: User

  validates :rating, presence: true
  validates :text, presence: true

  def rating=(rating)
    rating = rating.to_f
    rating = if rating > 5.0
               5.0
             elsif rating < 0.5
               0.5
             else
               MathExtras.round_to_half_decimal(rating)
             end

    super(rating)
  end

end
