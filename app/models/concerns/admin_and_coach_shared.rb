module AdminAndCoachShared
  extend ActiveSupport::Concern

  included do
    attr_accessor :without_password

    validates :first_name, presence: true, length: { maximum: 50 }
    validates :last_name, presence: true, length: { maximum: 50 }

    belongs_to :company, class_name: 'Company'

    scope :search, ->(term) do
      where('first_name ilike :term or last_name ilike :term or email ilike :term', term: "%#{term}%")
    end

    validates :email, email: true

    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
      :recoverable, :rememberable, :trackable, :validatable,
      :confirmable

    def role?(level)
      self.level == level
    end

    def has_password?
      encrypted_password.present?
    end

    def full_name
      "#{first_name} #{last_name}"
    end

    def password_required?
      super unless without_password
    end

    def self.authenticate(email, password)
      user = find_for_authentication(email: email)
      (user && user.valid_password?(password)) ? user : nil
    end

    def update_without_validations(attributes)
      assign_attributes attributes
      save validate: false
    end

    def default_authentication_payload_fields
      %i(id email first_name last_name company_id level clock_type locale)
    end

    def special_authentication_payload_fields
      []
    end

    def authentication_payload
      return nil if new_record?
      fields = default_authentication_payload_fields + special_authentication_payload_fields
      payload = fields.reduce({}) do |sum, method|
        safe_method_name = method.to_s.tr('?!', '').to_sym
        sum.merge(safe_method_name => public_send(method))
      end
      currency = if company
        # currency could be nil. Infer currency from the country then
        company.currency || (company.country.FI? ? 'eur' : 'usd')
      else
        # fallback for users which registered a long time ago but never used the app
        'usd'
      end
      token = AuthToken.encode(payload.merge(currency: currency, type: self.class.to_s), key_field: :admin_secret_key_base)
      { auth_token: token }
    end
  end
end
