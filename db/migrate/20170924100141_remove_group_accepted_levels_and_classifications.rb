class RemoveGroupAcceptedLevelsAndClassifications < ActiveRecord::Migration
  def up
    rename_column :groups, :accepted_skill_levels, :skill_levels

    Group.find_each do |group|
      group.skill_levels = group.skill_levels + [group.primary_skill_level]
      group.save
    end

    remove_column :groups, :primary_skill_level
  end

  def down
    add_column :groups, :primary_skill_level, :float

    Group.find_each do |group|
      group.primary_skill_level = group.skill_levels.to_a.last
      group.save
    end

    rename_column :groups, :skill_levels, :accepted_skill_levels
  end
end
