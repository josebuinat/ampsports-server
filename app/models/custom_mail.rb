# Represents an email message
class CustomMail < ActiveRecord::Base
  belongs_to :venue
  has_many :custom_mail_email_list_connectors, dependent: :destroy
  has_many :email_lists, through: :custom_mail_email_list_connectors
  has_many :users, through: :email_lists

  after_commit :send_mail, on: :create

  has_attached_file :image, styles: { medium: '300x300', thumb: '100x100'}
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  validate :has_recipients
  validates :from, presence: true

  def recipient_emails
    # can't just call users, rails can't find relation for model which is not yet persisted to the DB
    list_users = User.joins(:email_list_user_connectors).
      where(email_list_user_connectors: { email_list_id: email_lists.map(&:id) })
    @recipient_emails ||= (list_users.map(&:email) + recipient_users.to_s.split(',')).uniq
  end

  def send_mail
    CustomMailWorker.perform_async(id)
  end

  # sends copy (sample) mail to specified email
  def send_test_mail(recipient_email)
    self.subject += ' <Copy>'
    CustomMailer.custom_mail(self, recipient_email).deliver_later
  end

  def self.build_custom_mail(mail_options, venue_id)
    self.new(
      mail_options.slice(:from, :subject, :body, :image)
      .merge(
        email_lists: EmailList.where(id: mail_options[:to_groups]),
        recipient_users: mail_options[:to_users].join(','),
        venue_id: venue_id
      )
    )
  end

  def to_groups=(value)
    self.email_lists = EmailList.where(id: value)
  end

  def to_groups
    email_lists.map(&:id)
  end

  def to_users=(value)
    sanitized_users = value.to_s.split(',').map(&:strip).reject(&:blank?).uniq.join(',')
    self.recipient_users = sanitized_users
  end

  def to_users
    recipient_users
  end

  def self.search(search_term)
    if search_term.present?
      where('subject iLike :term OR body iLike :term', term: "%#{search_term}%")
    else
      all
    end
  end

  private

  def has_recipients
    if recipient_emails.blank?
      errors[:base] << 'has no recipients'
    end
  end
end
