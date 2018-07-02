# Handles analytics using Segment.io
class SegmentAnalytics  
  def self.enabled?
    ENV['SEGMENT_ENABLED'] == 'enabled'
  end

  def self.analytics
    @analytics ||= Segment::Analytics.new(write_key: ENV['SEGMENT_WRITE_KEY'],
                                          on_error: Proc.new { |status, msg| Rails.logger.error "\nSEGMENT ANALYTICS ERROR: #{msg} #{status}\n" }) 
  end

  def self.all_venues_search(user, params)
    # track user if logged in
    if user.present?
      analytics.track(user_id: user.id,
                    event: 'All Venue Search',
                    properties: params)
    end
  end

  def self.search_for_venue(user, venue, params)
    # track user if logged in
    if user.present?
      analytics.track(user_id: user.id,
                    event: 'Search For Venue',
                    properties: params.merge(venue: venue.venue_name))
    end
  end

  def self.credit_card(user)
    time_from_signup = (Time.current - user.created_at).round
    analytics.track(
      user_id: user.id,
      event: 'Credit Card added by User',
      properties: { time_form_signup: time_from_signup,
                    user_type: user.class.name }
    )
  end

  def self.booking(venue, reservation, user, source = "User")
    analytics.track(
      user_id: user.id,
      event: "Paid Booking Done By #{source}",
      properties: {
        venue_id: venue.id,
        venue_name: venue.venue_name,
        reservation_id: reservation.id,
        first_reservation_timestamp: first_reservation_timestamp(user, reservation),
        price: reservation.price,
        court_id: reservation.court_id,
        user_type: user.class.name
      }
    )
  end

  def self.unpaid_booking(venue, reservation, user, source = "User")
    analytics.track(
      user_id: user.id,
      event: "Unpaid Booking Done By #{source}",
      properties: {
        venue_id: venue.id,
        venue_name: venue.venue_name,
        reservation_id: reservation.id,
        first_reservation_timestamp: first_reservation_timestamp(user, reservation),
        price: reservation.price,
        court_id: reservation.court_id,
        user_type: user.class.name
      }
    )
  end

  def self.recurring_reservation(venue, reservation, user)
    if user.id.present?
      analytics.track(
        user_id: user.id,
        event: "Reoccurring reservation",
        properties: {
          venue_id: venue.id,
          venue_name: venue.venue_name,
          price: reservation.price,
          court_id: reservation.court_id,
          user_type: user.class.name
        }
      )
    end
  end

  def self.cancellation(reservation, user, title)
    user ||= reservation.user
    venue = reservation.court.venue
    analytics.track(
      user_id: user&.id,
      event: title,
      properties: {
        owner_id: reservation.user.id,
        venue_id: venue.id,
        venue_name: venue.venue_name,
        price: reservation.price,
        court_id: reservation.court.id,
        user_type: user.class.name
      }
    )
  end

  def self.user_cancellation(reservation, user)
    cancellation(reservation, user, "Bookings Cancelled By User")
  end

  def self.admin_cancellation(reservation, user)
    cancellation(reservation, user, "Bookings Cancelled By Admin")
  end

  def self.cancellation_due_to_other_reservation(reservation, other_reservation)
    cancellation(reservation, other_reservation, "Booking of reservation took the shared court of another booking")
  end

  def self.unknown_cancellation(reservation, actor)
    cancellation(reservation, actor, "Booking canceled by unknown")
  end

  def self.user_resell(reservation, user)
    cancellation(reservation, user, "Booking Resell By User")
  end

  def self.admin_resell(reservation, user)
    cancellation(reservation, user, "Booking Resell By Admin")
  end

  def self.withdraw_resell_booking(reservation, actor)
    title = "Booking Sale Withdrawn by #{actor.class.name.demodulize}"
    resell_events(reservation, actor, title)
  end

  def self.sold_resell_booking(reservation, actor)
    title = "Booking Sold by #{actor.class.name.demodulize}"
    resell_events(reservation, actor, title)
  end

  def self.time_diff(start_time, end_time)
    start_time = Time.parse(start_time.to_s).utc
    end_time = Time.parse(end_time.to_s).utc
    (end_time - start_time).round
  end

  def self.first_reservation_timestamp(user, reservation)
    time_diff(user.created_at, reservation.created_at)
  end

  private_class_method :time_diff, :first_reservation_timestamp

  def self.resell_events(reservation, actor, title)
    Rails.logger.info "SEGMENT ANALYTICS:  #{title}"
    venue = reservation.court.venue
    analytics.track(
      user_id: actor.id,
      event: title,
      properties: {
        reservation_id: reservation.id,
        owner_id: reservation.user.id,
        owner_type: reservation.user.class.name,
        venue_id: venue.id,
        venue_name: venue.venue_name,
        price: reservation.price,
        court_id: reservation.court_id
      }
    )
  end

  def self.user_registered(user)
    analytics.track(
      user_id: user.id,
      event: "User Sign Up",
      properties: {
        user_id: user.id,
        user_name: user.full_name
      }
    )
  end

  def self.admin_created_user(user, admin)
    analytics.track(
      user_id: admin.id,
      event: "Admin Created User",
      properties: {
        user_id: user.id,
        user_name: user.full_name
      }
    )
  end

  def self.user_added_to_venue(user, venue, actor, title)
    analytics.track(
      user_id: actor.id,
      event: title,
      properties: {
        user_id: user.id,
        venue_id: venue.id,
        venue_name: venue.venue_name
      }
    )
  end

  def self.user_added_to_venue_via_online(user, venue)
    type = status_of_venue_user(user)
    title = "#{type} Online User Added to Venue"

    user_added_to_venue(user, venue, user, title)
  end

  def self.user_added_to_venue_via_admin(user, venue, admin)
    type = status_of_venue_user(user)
    title = "#{type} User Added to Venue by Admin"

    user_added_to_venue(user, venue, admin, title)
  end

  def self.status_of_venue_user(user)
    if user.venues.count > 1
      'Existing'
    else
      'New'
    end
  end
end
