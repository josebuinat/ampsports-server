class CreateAPISecretKeys < ActiveRecord::Migration
  def change
    create_table :api_secret_keys do |t|
      t.string :name, index: true, unique: true
      t.string :key
    end
  end
end
