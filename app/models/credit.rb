class Credit < ActiveRecord::Base
  belongs_to :user
  belongs_to :company

  belongs_to :creditable, polymorphic: true # optional dependency

  validates :user, :company, presence: true
end
