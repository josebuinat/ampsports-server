# We use this just to store coaches which were assigned to the membership upon creation
# We can't update them. We don't use them later (except for showing them in membership modal)
class Membership::CoachConnection < ActiveRecord::Base
  belongs_to :membership, required: true
  belongs_to :coach, required: true

  validates :coach_id, uniqueness: { scope: :membership_id }
end
