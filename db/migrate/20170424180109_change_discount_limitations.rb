class ChangeDiscountLimitations < ActiveRecord::Migration
  def up
    add_column :discounts, :court_sports, :string
    add_column :discounts, :court_surfaces, :string
    add_column :game_passes, :court_surfaces, :string
    convert_data_up
    change_column :discounts, :court_type,
                              "integer USING NULLIF(court_type, '')::int",
                              default: 0
    remove_column :discounts, :sports, :text
    remove_column :discounts, :surfaces, :text
  end

  def down
    add_column :discounts, :sports, :text
    add_column :discounts, :surfaces, :text
    change_column :discounts, :court_type, :string
    convert_data_down
    remove_column :discounts, :court_sports, :string
    remove_column :discounts, :court_surfaces, :string
    remove_column :game_passes, :court_surfaces, :string
  end

  def convert_data_up
    Discount.find_each do |discount|
      say "CONVERTING DISCOUNT #{discount.id}"
      # raw data to parsed with minute_of_a_day
      say "converting time limits: #{discount[:time_limitations]}"
      limits_array = discount[:time_limitations]
      discount[:time_limitations] = {}
      discount.time_limitations = limits_array
      say "result: #{discount[:time_limitations]}"
      # serialized array to string/nil
      say "converting sports: #{discount.sports}"
      sports = discount.sports
      sports = YAML.load(sports.to_s) if sports.to_s.start_with?('---')
      sports = [] unless sports.is_a?(Array)
      discount[:court_sports] = sports.any? ? sports.join(',') : nil
      say "resulting court_sports: #{discount.court_sports}"
      # serialized array to string/nil
      say "converting surfaces: #{discount.surfaces}"
      sports = discount.surfaces
      surfaces = YAML.load(surfaces.to_s) if surfaces.to_s.start_with?('---')
      surfaces = [] unless surfaces.is_a?(Array)
      discount[:court_surfaces] = surfaces.any? ? surfaces.join(',') : nil
      say "resulting court_surfaces: #{discount.court_surfaces}"
      # string to enum
      say "converting court_type: #{discount[:court_type]}"
      discount[:court_type] = Discount.court_types[discount[:court_type].to_s]
      say "resulting court_type: #{discount[:court_type]}"

      say discount.save ? "saved" : "not saved"
    end
  end

  def convert_data_down
    Discount.find_each do |discount|
      say "CONVERTING DISCOUNT #{discount.id}"
      # convert parsed minute_of_a_day time back to ActionController::Parameters raw data
      say "converting time limits: #{discount[:time_limitations]}"
      discount[:time_limitations] = discount.time_limitations
      say "result: #{discount[:time_limitations]}"
      # string to serialized array
      say "converting court_sports: #{discount.court_sports}"
      sports = discount[:court_sports] ? discount[:court_sports].split(',') : []
      discount.sports = sports.to_yaml
      say "resulting sports: #{discount.sports}"
      # string to serialized array
      say "converting court_surfaces: #{discount.court_surfaces}"
      surfaces = discount[:court_surfaces] ? discount[:court_surfaces].split(',') : []
      discount.surfaces = surfaces.to_yaml
      say "resulting surfaces: #{discount.surfaces}"
      # enum to string
      say "converting court_type: #{discount[:court_type]}"
      discount[:court_type] = Discount.court_types.invert[discount[:court_type].to_i]
      say "resulting court_type: #{discount[:court_type]}"

      say discount.save ? "saved" : "not saved"
    end
  end
end
