# Handles checking venue listing rules
module VenueStatus

  # checks all rules for changing status to searchable
  # - at least 1 court
  # - at least 1 photo
  # - business hours for all days
  # - at least 1 price for each court
  def validate_searchable
    errors.add(:status, I18n.t('errors.venue.list.court_empty')) if courts.empty?
    errors.add(:status, I18n.t('errors.venue.list.photos_empty')) if photos.empty?
    errors.add(:status, I18n.t('errors.venue.list.days_empty')) if errors.include?(:business_hours)
    errors.add(:pricing,
               I18n.t('errors.venue.list.price_not_specifying')) if courts.any? { |c| c.prices.empty? }

    if !company.can_be_listed_as_public? || !company.god_admin&.has_ssn?
      errors.add(:status, I18n.t('errors.venue.list.company'))
    end
  end
end
