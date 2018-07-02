class GamePass::CoachConnection < ActiveRecord::Base
  belongs_to :game_pass, required: true
  belongs_to :coach, required: true

  validates :coach_id, uniqueness: { scope: :game_pass_id }
end
