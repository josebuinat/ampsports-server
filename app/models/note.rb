# a note admin users can leave on admin area
class Note < ActiveRecord::Base
  self.table_name = 'company_notes'

  belongs_to :company, required: true
  belongs_to :last_edited_by, required: false, polymorphic: true
end