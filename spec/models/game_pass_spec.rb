require 'rails_helper'

RSpec.describe GamePass, type: :model do
  it 'can be created' do
    expect{create :game_pass}.not_to raise_error
  end
end
