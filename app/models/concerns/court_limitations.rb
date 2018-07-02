# court limitations parsing and checks for GamePass and Discount
# related fields: court_type(integer, def: 0), court_sports(string), court_surfaces(string)
module CourtLimitations
  extend ActiveSupport::Concern

  included do
    enum court_type: [:any, :indoor, :outdoor]

    scope :available_for_court, ->(court) do
      where(arel_table[:court_sports].eq(nil)
              .or(arel_table[:court_sports].eq(''))
              .or(arel_table[:court_sports].matches("%#{court.sport_name}%"))
      ).where(arel_table[:court_surfaces].eq(nil)
              .or(arel_table[:court_surfaces].eq(''))
              .or(arel_table[:court_surfaces].matches("%#{court.surface ? court.surface : 'other'}%"))
      ).where(arel_table[:court_type].eq(nil)
              .or(arel_table[:court_type].eq(0))
              .or(arel_table[:court_type].eq(court.indoor? ? 1 : 2))
      )
    end

    def court_sports
      self[:court_sports].to_s.split(',')
    end

    def court_sports=(raw_sports)
      sports = raw_sports.to_a.map(&:strip).map(&:downcase) & Court.sport_names.keys

      self[:court_sports] = sports.any? ? sports.join(',') : nil
    end

    def court_surfaces
      self[:court_surfaces].to_s.split(',')
    end

    def court_surfaces=(raw_surfaces)
      surfaces = raw_surfaces.to_a.map(&:strip).map(&:downcase) & Court.surfaces.keys

      self[:court_surfaces] = surfaces.any? ? surfaces.join(',') : nil
    end

    def court_type=(type)
      type = 0 if type.blank?
      super(type)
    end

    def self.court_types_options
      court_types.keys.map do |type|
        { value: type, label: Court.human_attribute_name("court_name.#{type}") }
      end
    end

    def court_sports_to_s
      if court_sports.any?
        court_sports.map do |sport|
          Court.human_attribute_name("sport_name.#{sport}")
        end.join(', ')
      else
        Court.human_attribute_name("sport_name.any")
      end
    end

    def court_surfaces_to_s
      if court_surfaces.any?
        court_surfaces.map do |surface|
          Court.human_attribute_name("surface.#{surface}")
        end.join(', ')
      else
        Court.human_attribute_name("surface.any")
      end
    end
  end
end
