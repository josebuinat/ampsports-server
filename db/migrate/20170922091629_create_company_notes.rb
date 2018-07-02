class CreateCompanyNotes < ActiveRecord::Migration
  def change
    create_table :company_notes do |t|
      t.belongs_to :company, index: true
      t.text :text, default: '', null: false
      t.belongs_to :last_edited_by, polymorphic: true, index: { name: 'index_company_notes_on_last_edited_by_type_polymorphic' }
      t.timestamps
    end
  end
end
