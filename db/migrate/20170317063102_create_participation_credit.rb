class CreateParticipationCredit < ActiveRecord::Migration
  def change
    create_table :participation_credits do |t|
      t.belongs_to  :user, index: true, foreign_key: true
      t.belongs_to  :company, index: true, foreign_key: true
      t.belongs_to  :group_classification, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
