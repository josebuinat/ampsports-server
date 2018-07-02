class Group::CoachConnection < ActiveRecord::Base
  belongs_to :group, required: true
  belongs_to :coach, required: true

  validates :coach_id, uniqueness: { scope: :group_id }

  after_create :send_welcome_email
  after_destroy :send_cancellation_email

  private

  def send_cancellation_email
    GroupMailer.coach_removed_from_the_group(group, coach).deliver_later
  end

  def send_welcome_email
    GroupMailer.coach_added_to_the_group(group, coach).deliver_later
  end
end
