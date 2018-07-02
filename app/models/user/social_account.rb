class User::SocialAccount < ActiveRecord::Base
  belongs_to :user, required: true
  
  validates :uid, presence: true, uniqueness: { scope: [:user, :provider] }
  validates :provider, presence: true, uniqueness: { scope: :user }
end
