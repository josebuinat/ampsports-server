class Admin::BaseController < ActionController::Base
  include Punditable
  before_action :set_default_response_format
  include SignatureProtected
  protect_from_forgery with: :null_session
  # some controllers don't need this will skip it on their own
  before_action :authenticate_request!
  before_action :set_locale
  include ClockTypeTimeFormat

  # Custom classes for authentication
  class NotAuthenticatedError < StandardError; end
  class AuthenticationTimeoutError < StandardError; end
  class WrongActionError < StandardError; end
  class ForbiddenError < StandardError; end

  rescue_from AuthenticationTimeoutError, with: :authentication_timeout
  rescue_from NotAuthenticatedError, with: :user_not_authenticated
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
  rescue_from WrongActionError, :with => :bad_request
  rescue_from ForbiddenError, :with => :forbidden_request

  protected

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end

  def self.validate_access_level(level)
    raise ForbiddenError if current_admin.level != level.to_s
  end

  def set_default_response_format
    request.format = :json
  end

  def authenticate_request!
    @current_admin =  if decoded_auth_token[:type] == 'Coach'
                        ::Coach.find(decoded_auth_token[:id])
                      else
                        ::Admin.find(decoded_auth_token[:id])
                      end
    sign_in(@current_admin)
    # TODO: company is not something we need in every request, therefore define
    # lazy-loading helper method current_company
    @current_company = @current_admin.company
  rescue JWT::ExpiredSignature, JWT::ImmatureSignature
    raise AuthenticationTimeoutError
  rescue JWT::VerificationError, JWT::DecodeError, ActiveRecord::RecordNotFound
    raise NotAuthenticatedError
  end

  def pundit_user
    @current_admin
  end

  def record_not_found
    render json: { errors: [I18n.t('api.record_not_found')] }, status: :not_found
  end

  def bad_request
    render json: { errors: ['bad request'] }, status: :bad_request
  end

  def set_locale
    proposed_locale = request.headers['Locale'] || @current_admin&.locale
    # symbols are garbage collected nowadays, no DOS possible here
    new_locale = if I18n.available_locales.include?(proposed_locale&.to_sym)
      proposed_locale
    else
      I18n.default_locale
    end

    I18n.locale = new_locale
  end

  # Decode the authorization header token and return the payload
  def decoded_auth_token
    @decoded_auth_token ||= AuthToken.decode(http_auth_token, key_field: :admin_secret_key_base)
  end

  # Raw Authorization Header token (json web token format)
  # JWT's are stored in the Authorization header using this format:
  # Bearer somerandomstring.encoded-payload.anotherrandomstring
  def http_auth_token
    @http_auth_token ||= if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

  def authentication_timeout
    render json: { errors: [I18n.t('api.authentication.timeout')] }, status: 419
  end

  def user_not_authenticated
    render json: { errors: [I18n.t('api.authentication.unauthorized')] }, status: :unauthorized
  end

  def forbidden_request
    render json: { errors: ['Not enough permissions for that'] }, status: :forbidden
  end

  def use_timezone
    Time.use_zone(venue.timezone) { yield }
  end

  def use_clock_type
    Time.with_user_clock_type(current_admin) { yield }
  end
end
