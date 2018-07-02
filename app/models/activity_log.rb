# Represent an activity to recorded in the logs
# To record activites log for a model, put this line in that model:
#   has_many :activity_logs_payloads_connectors, as: :payloads
# define and call methods for building payload details and description in this file

class ActivityLog < ActiveRecord::Base
  belongs_to :company
  belongs_to :actor, polymorphic: true

  # polymorphic assication doesn't support 'has_many through'
  # so have to define methods payloads and payloads=
  has_many :activity_logs_payloads_connectors

  serialize :payload_details, Array

  enum activity_type: [
                        :reservation_created,
                        :reservation_updated,
                        :reservation_cancelled,
                        :membership_created,
                        :membership_updated,
                        :membership_cancelled,
                        :invoices_sent,
                        :participation_cancelled
                      ]

  validates :activity_type, presence: true

  # creates activity log with given activity_type, company_id, actor and payload
  def self.record_log(activity_type, company_id, actor, payloads, remote_ip = '')
    payloads = [payloads] if !payloads.respond_to?('each')
    activity_log = ActivityLog.new(
      activity_type: activity_type,
      actor: actor,
      actor_name: actor&.full_name || remote_ip,
      activity_time: payloads.first.updated_at,
      company_id: company_id,
      payloads: payloads
    )
    return if !activity_log.activity_loggable?
    activity_log.build_payload_details
    activity_log.save
  end

  # add payload details for given payload to save
  def build_payload_details
    method_name = "build_#{payload_type.downcase}_details"
    self.send method_name
  end

  def payloads
    self.activity_logs_payloads_connectors.map(&:payload)
  end

  def payload_type
    self.activity_logs_payloads_connectors.first&.payload_type
  end

  def payloads=(payloads)
    self.activity_logs_payloads_connectors = payloads.map do |payload|
                                               ActivityLogsPayloadsConnector.new(payload: payload)
                                             end
  end

  def activity_loggable?
    of_type_update? ? payloads.any? { |payload| payload.previous_changes.present? } : true
  end

  def self.search(args = {})
    relation = self.all

    term = args[:search_term].to_s.strip.downcase
    if term.present?
      term = "%#{term}%"
      relation = relation.where(arel_table[:payload_details].matches(term).
                        or(arel_table[:actor_name].matches(term))
                      )
    end

    start_date = args[:filter_start_date]

    if start_date.present?
      start_date = TimeSanitizer.input(TimeSanitizer.output(start_date).beginning_of_day.to_s)
      relation = relation.where(arel_table[:created_at].gteq(start_date))
    end

    end_date = args[:filter_end_date]
    if end_date.present?
      end_date = TimeSanitizer.input(TimeSanitizer.output(end_date).end_of_day.to_s)
      relation = relation.where(arel_table[:created_at].lteq(end_date))
    end

    payload_type, action_type = args[:filter_payload_types], args[:filter_action_types]
    if payload_type.present? || action_type.present?
      types = ActivityLog.activity_types.
                        select{ |key, _| [payload_type, action_type].compact.all? { |term| key.include?(term) } }.
                        values
      relation = relation.where(activity_type: types)
    end

    relation
  end

  def description
    method_name = "build_#{payload_type.downcase}_description"
    self.send method_name
  end

  private

  def build_reservation_details
    details = self.payloads.map do |payload|
      detail = payload.slice(
                        :start_time,
                        :end_time,
                        :payment_type,
                        :price,
                        :amount_paid,
                        :user_type,
                        :user_id,
                        :note
                      ).
                      merge(
                        payload_type: "Reservation",
                        user_name: payload.user&.full_name,
                        court_name: payload.court.court_name,
                        venue_name: payload.venue.venue_name
                      )

      detail[:changes] = payload_changes(payload) if of_type_update?
      detail
    end
    self.payload_details = details
  end

  def build_membership_details
    details = self.payloads.map do |payload|
      detail = payload.slice(
                        :start_time,
                        :end_time,
                        :price,
                        :user_id,
                        :title,
                        :note
                      ).merge(
                        payload_type: "Membership",
                        user_name: payload.user&.full_name,
                        venue_name: payload.venue.venue_name
                      )
      detail[:changes] = payload_changes(payload) if of_type_update?
      detail
    end
    self.payload_details = details
  end

  def build_invoice_details
    details = self.payloads.map do |payload|
      detail = payload.slice(
                        :reference_number,
                        :total,
                        :owner_id,
                        :owner_type,
                      ).merge(
                        payload_type: "Invoice",
                        user_name: payload.owner.full_name
                      )
      detail[:changes] = payload_changes(payload) if of_type_update?
      detail
    end
    self.payload_details = details
  end

  def payload_changes(payload)
    payload.previous_changes.except(:updated_at)
  end

  def of_type_update?
    self.activity_type.include?('updated')
  end

  def build_reservation_description
    count = payload_details.size
    label = "Reservation".pluralize(count)
    description = "#{count} #{label}:"
    currency = company.currency || I18n.t('number.currency.format.unit')

    description += payload_details.map do |r|
      court = r[:court_name]
      venue = r[:venue_name]
      from = TimeSanitizer.output(r[:start_time]).strftime('%Y-%m-%d %H:%M')
      till = TimeSanitizer.output(r[:end_time]).strftime('%H:%M')
      user = r[:user_name].humanize
      price = r[:price]
      due = r[:price] - r[:amount_paid]
      note = r[:note].present? ? ' note: ' + r[:note].truncate(20) : ''

      " at #{court} at #{venue} from #{from} till #{till} for #{user} \
        for #{price} #{currency} (due #{due} #{currency}) #{note}"
    end.join(",\n")
  end

  def build_membership_description
    count = payload_details.size
    label = "Recurring reservation".pluralize(count)
    description = "#{count} #{label}:"
    currency = company.currency || I18n.t('number.currency.format.unit')

    description += payload_details.map do |m|
      title = m[:title] ? ' with title' + m[:title] : ''
      venue = m[:venue_name]
      from = TimeSanitizer.output(m[:start_time]).strftime('%Y-%m-%d %H:%M')
      to = TimeSanitizer.output(m[:end_time]).strftime('%Y-%m-%d %H:%M')
      user = m[:user_name].humanize
      price = m[:price]
      note = m[:note].present? ? "note: #{m[:note].truncate(20)}" : ''

      "#{title} at #{venue} from #{from} to #{to} for #{user} for #{price} #{currency} #{note}"
    end.join(",\n")
  end

  def build_invoice_description
    count = payload_details.size
    label = "Invoice".pluralize(count)
    description = "#{count} #{label}:"
    currency = company.currency || I18n.t('number.currency.format.unit')

    description += payload_details.map do |invoice|
      ref = invoice[:reference_number]
      name = invoice[:user_name].humanize
      total = invoice[:total]

      " reference number: #{ref} to #{name} for #{total} #{currency}"
    end.join(",\n")
  end
end
