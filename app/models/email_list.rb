# Represents a mailing group of users
class EmailList < ActiveRecord::Base
  belongs_to :venue
  has_many :email_list_user_connectors, dependent: :destroy
  has_many :users, through: :email_list_user_connectors
  has_many :custom_mail_email_list_connectors, dependent: :destroy
  has_many :custom_mails, through: :custom_mail_email_list_connectors

  validates :name, presence: true, uniqueness: { scope: :venue }
  validate :unique_users?

  def add_users(user_ids)
    new_users = off_list_users.subscription_enabled.where(id: user_ids)
    users.append(new_users)
  end

  def add_all_users
    sql_values = off_list_users.subscription_enabled.map do |user|
      "(#{id}, #{user.id}, '#{DateTime.current.utc.to_s}', '#{DateTime.current.utc.to_s}')"
    end

    return false if sql_values.blank?

    EmailList.connection.execute(
      <<~SQL,
        INSERT INTO email_list_user_connectors
          (email_list_id, user_id, created_at, updated_at)
        VALUES
          #{sql_values.join(",")}
      SQL
    )
  end

  # returns list of venue users not included in the email list
  # and those have subscribed for emails
  def off_list_users
    venue.users.where.not(id: email_list_user_connectors.select(:user_id))
  end

  private
  def unique_users?
    if users.length != users.uniq.length
      errors.add(:users, "duplicate users not allowed")
    end
  end
end
