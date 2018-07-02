class User < ActiveRecord::Base
  include Settings
  has_settings :email_notifications, {
    reservation_receipts: true,
    reservation_updates: true,
    reservation_cancellations: true
  }

  extend ActiveHash::Associations::ActiveRecordExtensions
  include CreditCards
  include ClockType
  include Sortable
  virtual_sorting_columns({
    full_name: {
      order: ->(direction) { "users.first_name #{direction}, users.last_name #{direction}" }
    },
    outstanding_balance: ->(additional_params){
      company_id = additional_params[:company].id
      {

        select: '(coalesce(outstanding.sum_price, 0) + coalesce(game_pass_outstanding.sum_price, 0)) as very_total',
        # Join reservations and game passes, mimic appropriate scopes with SQL (invoiceable)
        joins: <<~SQL,
          left outer join (#{Reservation.query_outstanding_balances_by_user(company_id).to_sql})
            outstanding on outstanding.user_id = users.id
          left outer join (#{GamePass.query_outstanding_balances_by_user(company_id).to_sql})
            game_pass_outstanding on game_pass_outstanding.user_id = users.id
        SQL
        order: 'very_total'
      }
    },
    lifetime_value: ->(additional_params) {
      company_id = additional_params[:company].id
      {
        select: '(coalesce(lifetime_values.sum_price, 0) + coalesce(game_pass_values.sum_price, 0)) as very_total',
        joins: <<~SQL,
          left outer join (#{Reservation.query_lifetime_values_by_user(company_id).to_sql})
            lifetime_values on lifetime_values.user_id = users.id
          left outer join (#{GamePass.query_lifetime_values_by_user(company_id).to_sql})
            game_pass_values on game_pass_values.user_id = users.id
      SQL
      order: 'very_total'
      }
    }
  })

  has_attached_file :photo,
                    styles: { small: "150x150#" }
  belongs_to_active_hash :default_country, class_name: 'Country', foreign_key: :default_country_id

  has_many :favourite_venues, dependent: :destroy
  has_many :favourites, through: :favourite_venues, source: :venue
  has_many :devices, dependent: :destroy
  has_many :reservations, as: :user, dependent: :destroy
  has_many :participant_connections, class_name: 'Reservation::ParticipantConnection', dependent: :destroy
  has_many :participating_reservations, through: :participant_connections, source: :reservation
  has_many :memberships, dependent: :destroy, as: :user
  has_many :venue_user_connectors, dependent: :destroy
  has_many :venues, through: :venue_user_connectors
  has_many :companies, through: :venues
  has_many :invoices, as: :owner
  has_many :discounts, through: :discount_connections
  has_many :discount_connections, dependent: :destroy
  has_many :email_list_user_connectors, dependent: :destroy
  has_many :email_lists, through: :email_list_user_connectors
  has_many :game_passes, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :social_accounts, dependent: :destroy, class_name: 'User::SocialAccount'
  has_many :reviews, foreign_key: 'author_id'
  has_many :activity_logs, as: :actor
  has_many :groups, as: :owner, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :group_subscriptions, dependent: :destroy
  has_many :participation_credits, dependent: :destroy

  # all new relations should be reflected in #replace_with_user method

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: [:facebook]

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, email: true
  # Because we allow users to sign up without a password we have to run some additional fancy checks
  # to ensure that if password is supplied we need to check for confirmation
  validates :password_confirmation, presence: true, if: ->(model) { model.password.present? }
  validates :password, confirmation: true, if: ->(model) { model.errors[:password_confirmation].blank? }
  validates_attachment_size :photo, less_than: 5.megabytes
  validates_attachment_content_type :photo, content_type: /\Aimage\/.*\Z/
  after_update :resend_confirmation

  scope :subscription_enabled, -> {
    joins(:venue_user_connectors).merge(VenueUserConnector.subscription_enabled)
  }

  # credit:
  # https://github.com/plataformatec/devise/wiki/How-To:-Find-a-user-when-you-have-their-credentials
  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
    (user && user.valid_password?(password)) ? user : nil
  end

  def tz
    # TimeZone[self.timezone] || Time.zone
    Time.zone # TODO: change me to ActiveSupport::TimeZone with actual user timezone in the future
  end

  def outstanding_balance(company=nil)
    return 0.0 if !company.present?
    reservation_balance = company.reservations.where(user:self).invoiceable.sum(:price)
      game_pass_balance = company.game_passes.where(user:self).invoiceable.sum(:price)

    reservation_balance.to_f + game_pass_balance.to_f
  end

  def has_stripe?
    return self.stripe_id != nil
  end

  def has_game_pass?(venue)
    self.game_passes.where(venue_id: venue.id).present?
  end

  def add_stripe_id(token)
    customer = Stripe::Customer.create(
      source: token,
      description: "Playven User"
    )
    self.update(stripe_id: customer.id)
  end

  def to_s
    full_name
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def get_billing_address
    street_address.to_s + ' ' + zipcode.to_s + ' ' + city.to_s
  end

  def activated?
    confirmed? || encrypted_password.present? || social_accounts.any?
  end

  def deletable?(for_company)
    !activated? && has_only_company?(for_company) && reservations.future.none?
  end

  def not_able_to_login?
    encrypted_password.blank? && unconfirmed?
  end

  def has_password?
    encrypted_password.present?
  end

  # returns available discount or nil
  def discount_for(court, start_time, end_time)
    available_discounts(court, start_time, end_time).first
  end

  # returns Array
  def available_discounts(court, start_time, end_time)
    sanitized_start_time = TimeSanitizer.output(start_time)
    sanitized_end_time = TimeSanitizer.output(end_time)

    discounts.
      where(venue: court.venue).
      available_for_court(court).
      available_for_date(sanitized_start_time.to_date, sanitized_end_time.to_date).
      to_a.select { |discount| discount.usable_at?(sanitized_start_time, sanitized_end_time) }
  end

  # returns Array
  def available_game_passes(court, start_time, end_time, coach_ids)
    sanitized_start_time = TimeSanitizer.output(start_time)
    sanitized_end_time = TimeSanitizer.output(end_time)
    hours = TimeSanitizer.duration(start_time, end_time).to_f / (60 * 60)
    coach_ids = coach_ids.compact

    game_passes.
      where(venue: court.venue).
      active.
      has_charges(hours).
      available_for_court(court).
      with_coaches(coach_ids).
      available_for_date(sanitized_start_time.to_date, sanitized_end_time.to_date).
      to_a.select { |game_pass| game_pass.usable_at?(sanitized_start_time, sanitized_end_time) }
  end

  def has_social_account?(provider, uid)
    social_accounts.where(provider: provider, uid: uid).exists?
  end

  def password_required?
    super if confirmed?
  end

  def venue_discount(venue)
    discounts.find { |discount| discount.venue == venue }
  end

  def segment_params
    {
      'email'           => email,
      'created'         => created_at,
      'first_name'      => first_name,
      'last_name'       => last_name,
      'id'               => id,
      'sign_in_count'    => sign_in_count,
      'last_sign_in'     => current_sign_in_at
    }
  end

  def reservations_with_resold
    Reservation.where(
      Reservation.arel_table[:user_id].eq(self.id).
      or(Reservation.arel_table[:initial_membership_id].in(memberships.ids))
    )
  end

  # returns UNION of users own reservation and participating_reservations
  # but without group participations and coached reservations
  def normal_reservations
    id_column = "#{Reservation.table_name}.id"
    scopes = [reservations, participating_reservations]
    sub_query = scopes.map { |scope| scope.select(id_column).to_sql }.join(" UNION ")
    Reservation.where("#{id_column} IN (#{sub_query})").non_coached
  end

  def future_reservations
    normal_reservations.non_recurring.future
  end

  def past_reservations
    normal_reservations.non_recurring.past
  end

  def future_memberships
    reservations.recurring.not_reselling.future
  end

  def past_memberships
    reservations.recurring.not_reselling.past
  end

  def reselling_memberships_future
    reservations.recurring.reselling.future
  end

  def reselling_memberships_past
    reservations.recurring.reselling.past
  end

  def resold_memberships_future
    Reservation.where(initial_membership_id: memberships.map(&:id)).future
  end

  def resold_memberships_past
    Reservation.where(initial_membership_id: memberships.map(&:id)).past
  end

  # coached reservations owned or participated by user, or group reservations
  def lessons
    Reservation.joining { [coach_connections.outer,
                           participant_connections.outer,
                           participations.outer] }.
      where.has { |r|
        (r.coach_connections.id != nil) & (
          (r.user_id == id) & (r.user_type == 'User') |
          (r.participant_connections.user_id == id) & (r.user_type.in ['User', 'Coach'])
        ) | (r.participations.user_id == id) & (r.participations.cancelled == false) & (r.user_type == 'Group')
      }.distinct
  end

  def assign_discount(discount)
    old_discount = discounts.find_by(venue_id: discount.venue_id)
    discounts.delete(old_discount.id) if old_discount
    discounts << discount
  end

  def unconfirmed?
    !confirmed?
  end


  def has_only_company?(company)
    companies.length == 1 && companies.include?(company)
  end

  def self.find_or_create_by_email(user_params, venue)
    if user_params[:user_id]
      User.find(user_params[:user_id])
    else
      User.find_or_create_by(email: user_params[:email]) do |user|
        user_attributes = user_params.permit(
          :first_name, :last_name,
          :email, :phone_number, :city,
          :street_address, :zipcode, :locale
        )
        user_attributes[:locale] = I18n.locale if user_attributes[:locale].blank?

        user.assign_attributes(user_attributes)
        venue.add_customer(user)
      end
    end
  end

  def authentication_payload
    return nil if new_record?
    fields = %w(id email first_name last_name phone_number stripe_id
                street_address zipcode city)
    attributes_hash = attributes.slice(*fields).with_indifferent_access.
      merge({
              image: profile_picture,
              country_id: default_country&.id,
              country_code: default_country&.iso_2,
              favourite_venues: favourites.pluck(:id),
              clock_type: clock_type.to_s,
              locale: locale
            })
    token = AuthToken.encode(attributes_hash)
    { auth_token: token }
  end

  def self.search(term)
    term = term.to_s.strip
    if term.present?
      where("(trim(both ' ' from first_name) || ' ' || trim(both ' ' from last_name)) ILIKE :term OR
                   users.email ILIKE :term OR
                   users.phone_number ILIKE :term",
                   term: "%#{term}%")
    else
      all
    end
  end

  def resend_confirmation
    if email_changed? && not_able_to_login?
      ConfirmationMailer.confirmation_instructions(
        self,
        self.confirmation_token
      ).deliver_later
    end
  end

  def replace_with_user(new_user)
    transaction do
      reservations.update_all(user_id: new_user.id)
      memberships.update_all(user_id: new_user.id)
      # venue_user_connectors, should not replace shared user
      invoices.update_all(owner_id: new_user.id)
      discount_connections.update_all(user_id: new_user.id)
      email_list_user_connectors.update_all(user_id: new_user.id)
      game_passes.update_all(user_id: new_user.id)
      credits.update_all(user_id: new_user.id)
      # social_accounts, should not replace active user
      reviews.update_all(author_id: new_user.id)
      activity_logs.update_all(actor_id: new_user.id,
                               actor_name: new_user.full_name,
                               actor_type: 'User')
      groups.update_all(owner_id: new_user.id)
      participations.update_all(user_id: new_user.id)
      group_subscriptions.update_all(user_id: new_user.id)
      participation_credits.update_all(user_id: new_user.id)
      owned_settings.update_all(owner_id: new_user.id)
      participant_connections.update_all(user_id: new_user.id)

      destroy
    end

    new_user.reload
  end

  def profile_picture
    photo.file? ? photo.url(:small) : image
  end

  def toggle_email_subscription_for(venue)
    connector = venue_user_connectors.find_by!(venue: venue)

    connector.email_subscription = !connector.email_subscription
    # remove the user from email lists
    if !connector.email_subscription
      email_lists.where(venue: venue).each do |email_list|
        email_list.users.delete(self)
      end
    end
    connector.save
  end

  def subscription_enabled?(venue)
    venue_user_connectors.find_by(venue: venue)&.email_subscription || false
  end
end
