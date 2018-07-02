module SportNames extend ActiveSupport::Concern
  included do
    enum sport_name: [:tennis,
                      :squash,
                      :badminton,
                      :golf,
                      :volleyball,
                      :soccer,
                      :floorball,
                      :tabletennis,
                      :spinning,
                      :billiard,
                      :snooker,
                      :gym]

    scope :for_sport, ->(sport) do
      clause = if sport.blank? || ['all', 'any'].include?(sport)
        nil
      else
        desired_sports = if sport.is_a?(Array)
          sport.map { |x| sport_names[x.to_s] }
        else
          sport_names[sport.to_s]
        end
        { sport_name: desired_sports }
      end
      where(clause)
    end

    def sport_name_id
      self.class.sport_names[sport_name]
    end
  end
end
