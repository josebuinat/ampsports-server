# Represents company admins
class Admin < ActiveRecord::Base
  include AdminAndCoachShared
  include Passport
  include ClockType
  include AdminPermissions
  include Sortable
  virtual_sorting_columns({
    full_name: {
      order: ->(direction) { "admins.first_name #{direction}, admins.last_name #{direction}" }
    }
  })

  has_many :activity_logs, as: :actor

  validate :one_god, if: 'god? && !company.nil?'

  after_save :make_god, unless: 'company.nil? || god?'

  enum level: [:guest, :cashier, :manager, :god]

  LEVEL_HUMANIZED = {
    'god' => 'Super Admin',
    'manager' => 'Manager',
    'cashier' => 'Employee',
    'guest' => 'N/A'
  }.freeze

  before_save { self.level ||= :god }

  def has_ssn?
    admin_ssn.present?
  end

  def level_to_s
    LEVEL_HUMANIZED[level]
  end

  def birth_date=(value)
    time_sanitizer_input = TimeSanitizer.input(value)
    self.admin_birth_day = time_sanitizer_input.day
    self.admin_birth_month = time_sanitizer_input.month
    self.admin_birth_year = time_sanitizer_input.year
  end

  def birth_date
    Date.parse("#{admin_birth_day}/#{admin_birth_month}/#{admin_birth_year}") rescue nil
  end

  # A hack to overcome open() aversion to certain file names
  def randomize_file_name
    extension = File.extname(passport_file_name).downcase
    passport.instance_write(:file_name, "deep-space#{extension}")
  end

  def one_god
    if company.admins.select(&:god?).count > 1
      errors.add('Company', ' can only have one and only one super admin')
    end
  end

  def make_god
    update(level: :god) if company.admins.count == 1
  end

  def special_authentication_payload_fields
    %i(admin_ssn)
  end

end
