# extend model with a configurable settings interface
module Settings
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :settings_config

    def has_settings(scope, params)
      define_method scope do
        settings(scope)
      end

      @settings_config ||= {}
      @settings_config[scope.to_sym] = params
    end

    def has_settings?(scope)
      @settings_config[scope.to_sym].present?
    end
  end

  included do
    has_many :owned_settings, class_name: 'Setting', as: :owner, dependent: :destroy

    def settings(scope)
      @settings ||= {}
      @settings[scope] ||= Interface.new(self, scope, self.class.settings_config[scope.to_sym])
    end
  end

  class Error < StandardError; end

  class Interface
    attr_reader :owner, :scope, :config

    def initialize(owner, scope, config)
      raise Error, I18n.t('errors.settings.invalid_owner') unless owner.is_a?(ActiveRecord::Base) &&
                                                                  owner.persisted?
      raise Error, I18n.t('errors.settings.invalid_scope') if scope.to_s.blank? || config.blank?

      @owner = owner
      @scope = scope.to_sym
      @config = config
    end

    def has?(name)
      return false if name.blank?
      config.key?(name.to_sym)
    end

    def validate_name!(name)
      raise Error, I18n.t('errors.settings.invalid_name') unless has?(name)
    end

    def get(name)
      validate_name!(name)

      setting = get_setting(name)
      setting.present? ? convert(name, setting.value) : default(name)
    end

    # returns true on success
    def put(name, value)
      validate_name!(name)

      setting = get_setting(name)

      if setting.present?
        setting.update(value: value)
      else
        new_setting = Setting.create(owner: owner, name: db_setting_name(name), value: value)
        settings << new_setting if new_setting.persisted?
        new_setting.persisted?
      end
    end

    def list
      config.keys.map do |name|
        { name: name.to_s, value: get(name) }
      end
    end

    def reload
      @settings = nil
      settings
      self
    end

    private

    def db_setting_name(name)
      "#{scope}_#{name}"
    end

    def db_setting_names
      config.keys.map { |name| db_setting_name(name) }
    end

    def settings
      @settings ||= Setting.where(owner: owner, name: db_setting_names).to_a
    end

    def get_setting(name)
      settings.find { |setting| setting.name == db_setting_name(name) }
    end

    def default(name)
      config[name.to_sym]
    end

    # initial value is a string, convert to the Type of default value
    def convert(name, value)
      case default(name)
      when TrueClass, FalseClass
        value == 't' || value == 'true'
      when Integer
        value.to_i
      when Float
        value.to_f
      else
        value
      end
    end
  end
end
