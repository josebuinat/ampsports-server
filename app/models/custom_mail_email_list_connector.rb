# Represents relationship between email_message and email_list models
class CustomMailEmailListConnector < ActiveRecord::Base
  belongs_to :email_list
  belongs_to :email_message
end
