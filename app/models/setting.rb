class Setting < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  validates :owner, :name, :value, presence: true
end
