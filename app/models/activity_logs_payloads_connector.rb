# Connecting class for activity_logs and payloads
# Payload can be either of Reservation, Membership, Invoice

# polymorphic assication doesn't support 'has_many through' so have to define
# methods payloads and payloads= in the ActivityLog class
class ActivityLogsPayloadsConnector < ActiveRecord::Base
  belongs_to :activity_log
  belongs_to :payload, polymorphic: true


  def payload
    if payload_type == "Reservation"
      # override default scope of inactive: false
      Reservation.unscoped { super }
    else
      super
    end
  end
end
