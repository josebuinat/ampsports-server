class RemoveNullFromCourtsIndoor < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        count = Court.where(indoor: nil).update_all(indoor: false)
        puts " --> Updated #{count} nil court/indoor values to false"
      end
    end

    change_column_null :courts, :indoor, false
    change_column_default :courts, :indoor, false
  end
end
