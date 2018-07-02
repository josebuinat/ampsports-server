class CreateCustomMailEmailListConnectors < ActiveRecord::Migration
  def change
    create_table :custom_mail_email_list_connectors do |t|
      t.belongs_to :custom_mail, index: true, foreign_key: true
      t.belongs_to :email_list, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
