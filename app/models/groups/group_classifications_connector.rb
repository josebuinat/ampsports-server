# represents has_and_belongs_to_many association between groups and group_classifications
class GroupClassificationsConnector < ActiveRecord::Base
  belongs_to :group, required: true
  belongs_to :group_classification, required: true
end
