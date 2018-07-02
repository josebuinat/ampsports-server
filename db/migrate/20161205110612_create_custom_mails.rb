class CreateCustomMails < ActiveRecord::Migration
  def change
    create_table :custom_mails do |t|
      t.text :recipient_users
      t.string :from
      t.string :subject
      t.text :body
      t.attachment :image
      t.belongs_to :venue, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
