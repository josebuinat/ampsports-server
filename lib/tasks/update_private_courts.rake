namespace :db do
  desc 'Set private flag for private courts by custom name presense.'
  task update_private_courts: :environment do
    Court.transaction do |variable|
      Court.where.not(custom_name: nil).update_all(private: true)
    end
  end
end
