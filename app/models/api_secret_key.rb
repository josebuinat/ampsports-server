# used to sign every API request, so nobody but us can use our APIs
class APISecretKey < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :key, presence: true
end