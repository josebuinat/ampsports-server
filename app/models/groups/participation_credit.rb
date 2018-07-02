class ParticipationCredit < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  belongs_to :group_classification

  validates :user, :company, :group_classification, presence: true

  def applicable_groups
    company.groups.
            accepts_classification(group_classification).
            accepts_skill_level(user.skill_level)
  end

  def applicable_reservations
    company.reservations.joins(
      <<-SQL
        INNER JOIN groups ON reservations.user_id = groups.id
            AND groups.id IN (#{applicable_groups.select(:id).to_sql})
      SQL
    ).where(
      "user_type = 'Group' AND participations_count < groups.max_participants"
    )
  end

  def applicable_reservation?(reservation)
    applicable_reservations.where(id: reservation.id).any?
  end

  def use_for(reservation)
    if applicable_reservation?(reservation)
      transaction do
        if create_participation_for(reservation) && self.destroy
          true
        else
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  def create_participation_for(reservation)
    reservation.participations.create(user: user, is_paid: true, price: 0)
  end
end
