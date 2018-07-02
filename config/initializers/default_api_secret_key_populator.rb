# Created default request signature API key for development
# We want developers to get up run fast & easy, so we need to make sure they have
# at least one valid key to work with. See more at RequestSignatureCalculator class
perform_signature = Rails.configuration.x.perform_request_signature_validation
is_a_rake_task = File.basename($0) == 'rake'
is_production = Rails.env.production?

# do not call on, say, db:migrate, in production or when it just not needed
if !is_a_rake_task && !is_production && perform_signature
  begin
    APISecretKey.find_or_create_by(name: 'dev-app', key: 'strong-and-secure-sample-key')
  rescue ActiveRecord::StatementInvalid => e
    puts '-' * 100
    puts 'If you see this error, then most likely you need to migrate your database before starting Rails server'
    puts '-' * 100
    raise e
  end
end