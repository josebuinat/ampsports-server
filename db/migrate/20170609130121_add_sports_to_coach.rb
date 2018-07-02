class AddSportsToCoach < ActiveRecord::Migration
  def change
    add_column :coaches, :sports, :string
  end
end
