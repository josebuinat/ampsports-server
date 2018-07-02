require 'rails_helper'

describe Search::ByName, type: :service do
  let!(:venue_1) { create :venue, :searchable, :with_courts, venue_name: 'cake' }
  let!(:venue_2) { create :venue, :searchable, :with_courts, venue_name: 'juicy' }
  let(:term) { 'uIc' }
  subject { search_instance.venues }

  describe '#venues' do
    context 'when country is not set' do
      let(:search_instance) { described_class.new(term: term, country: nil).call }

      it 'filters venues' do
        is_expected.to eq [venue_2]
      end
    end

    context 'when country is set' do
      let(:search_instance) { described_class.new(term: term, country: 'FI').call }

      it 'filters venues' do
        is_expected.to eq [venue_2]
      end

      context 'when search country differs from venue country' do
        before do
          [venue_1, venue_2].each{ |venue| venue.update!(country_id: 2)}
        end

        it 'filters venues' do
          is_expected.to eq []
        end
      end
    end
  end
end
