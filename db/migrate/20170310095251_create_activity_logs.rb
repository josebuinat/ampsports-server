class CreateActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.integer :activity_type, null: false
      t.text :payload_details, null: false
      t.string :actor_name, null: false
      t.datetime :activity_time, null: false
      t.references :actor, polymorphic: true, index: true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end

    create_table :activity_logs_payloads_connectors do |t|
      t.references :activity_log, index: true
      t.references :payload, polymorphic: true, index: {name: 'index_payload_connectors_on_payloads'}

      t.timestamps null: false
    end
  end
end
