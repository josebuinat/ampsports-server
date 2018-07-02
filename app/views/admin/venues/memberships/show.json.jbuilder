json.partial! 'base', membership: @membership

json.coach_name @membership.coaches.map(&:full_name).join(', ')
