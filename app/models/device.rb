class Device < ActiveRecord::Base
  belongs_to :user
  validates :token, presence: true
  validates :user, presence: true
end
