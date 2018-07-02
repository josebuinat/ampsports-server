namespace :db do
  desc 'Create coach connections from coach_id and salary.'
  task migrate_coaches: :environment do
    Coach.transaction do
      p 'Starting migration of groups coaches'
      Group.where.not(coach_id: nil).find_each do |group|
        coach = Coach.find_by(id: group[:coach_id])
        if coach
          if group.update(coach_id: nil, coaches: [coach])
            p "Migrated coach #{coach.full_name} for #{group.name}"
          else
            p "Failed to migrate coach #{coach.full_name} for #{group.name}"
          end
        else
          p "Can't find coach with ID #{group[:coach_id]} for #{group.name}, resetting it"
          group.update_column(:coach_id, nil)
        end
      end
      p 'Ended migration of groups coaches'

      p 'Starting migration of reservations coaches'
      Reservation.where.not(coach_id: nil).find_each do |reservation|
        coach = Coach.find_by(id: reservation[:coach_id])
        if coach
          if reservation.coach_connections.create(coach_id: coach.id,
                                                  salary: reservation[:coach_salary],
                                                  salary_paid: reservation[:coach_salary_paid])
            reservation.update_column(:coach_id, nil)
            p "Migrated coach #{coach.full_name} for ##{reservation.id}"
          else
            p "Failed to migrate coach #{coach.full_name} for ##{reservation.id}"
          end
        else
          p "Can't find coach with ID #{reservation[:coach_id]} for ##{reservation.id}, resetting it"
          reservation.update_column(:coach_id, nil)
        end
      end
      p 'Ended migration of reservations coaches'
    end
    p 'Changes successfully saves'
  end
end
