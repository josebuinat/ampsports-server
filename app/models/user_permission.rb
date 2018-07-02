class UserPermission < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  validates :owner, :permission, :value, presence: true
end
