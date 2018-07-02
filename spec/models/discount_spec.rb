require 'rails_helper'

RSpec.describe Discount, type: :model do
  before(:all) do
    @venue = FactoryGirl.create(:venue)
  end

  after(:all) do
    @venue.destroy
  end

  let (:discount) { FactoryGirl.create(:discount, venue: @venue) }

  describe 'validations' do
    it 'will be valid' do
      expect(discount).to be_valid
    end

    it 'wont be created without a name' do
      discount.name = nil
      expect(discount).not_to be_valid
    end

    it 'wont be created without a value' do
       discount.value = nil
       expect(discount).not_to be_valid
    end

    it 'wont be created without a method' do
      discount.method = nil
      expect(discount).not_to be_valid
    end

    it 'wont create a discount with wrong percentage' do
      discount.value = 110
      expect(discount).not_to be_valid
    end
  end
end
