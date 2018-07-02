class State < ActiveYaml::Base
  include ActiveHash::Associations

  set_root_path "app/fixtures"
  set_filename "states"


  class << self
    def find_state(state)
      find_by_iso_2(state.upcase) || find_by_abbreviation(state.upcase) || find_by_name(state)
    end
  end
end
