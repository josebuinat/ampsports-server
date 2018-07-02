class EmailValidator < ActiveModel::EachValidator
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def validate_each(record, attribute, value)
    unless value =~ VALID_EMAIL_REGEX
      record.errors[attribute] << (options[:message] || I18n.t('activerecord.errors.validations.email'))
    end
  end
end