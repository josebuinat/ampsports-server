require 'rails_helper'

RSpec.describe Venue, type: :model do
  describe '#validate_business_hours' do
    let(:venue) { build :venue, status: Venue.statuses[:prepopulated] }

    it 'passes validation with complete business hours' do
      expect(venue.valid?).to be_truthy
    end

    it 'adds error if business hours are invalid' do
      venue.business_hours[:wed][:opening] = nil
      venue.valid?
      error_message = I18n.t('errors.venue.business_hours.opening', day: I18n.t("errors.venue.list.wed"))
      expect(venue.errors.messages).to include(business_hours: [error_message])
    end
  end

  describe 'location fetch' do
    before(:all) do
      @venue = FactoryGirl.build(:venue)
    end
    let(:venue) { build :venue }

    after(:all) do
      Company.delete_all
      Admin.delete_all
    end

    it 'should take country from company' do
      company = create :company, country: Country.find_country('US')
      venue = create :venue, country_id: nil, company: company
      expect(venue.country.name).to eq 'USA'
    end

    it 'should generate lat/long from address' do
      venue.latitude = nil
      venue.longitude = nil
      venue.save
      expect(venue.latitude).not_to eq(nil)
      expect(venue.longitude).not_to eq(nil)
    end

    it 'should generate timezone from address' do
      venue.timezone = nil
      venue.latitude = nil
      venue.longitude = nil
      VCR.use_cassette('venue_location_lookup') do
        venue.save
      end
      expect(venue.timezone).to eq 'America/Los_Angeles'
    end

    it 'should wait for address change' do
      venue.save
      venue.longitude = nil
      venue.latitude = nil
      venue.valid?
      expect(venue.latitude).to eq(nil)
      expect(venue.longitude).to eq(nil)
    end
  end

  describe '#available_court_indexes' do
    let!(:venue) { create :venue, :with_courts, court_count: 2 }
    let!(:court1) { venue.courts.first }
    let!(:court2) { venue.courts.second }
    let!(:new_court) { build :court, venue: venue}

    context 'invalid court' do
      it 'rejects nil court' do
        expect(venue.available_court_indexes(nil)).to eq []
      end

      it 'rejects not a court' do
        expect(venue.available_court_indexes(venue)).to eq []
      end

      it 'rejects court without sport or custom name' do
        new_court.sport_name = nil
        new_court.custom_name = nil

        expect(venue.available_court_indexes(new_court)).to eq []
      end
    end

    context 'for new court' do
      subject { venue.available_court_indexes(new_court) }

      context 'indoor type and sport name' do
        it 'finds next available index 3, ignoring custom name' do
          expect(subject.first).to eq 3
        end
      end

      context 'custom name' do
        before(:each) do
          new_court.custom_name = 'custom'
        end

        it 'finds next available index 1, ignoring sport and type' do
          expect(subject.first).to eq 1
        end
      end
    end

    context 'for existing court(with index of self)' do
      subject { venue.available_court_indexes(court1) }

      context 'indoor type and sport name' do
        it 'finds next available same as current index, ignoring custom name' do
          expect(subject.first).to eq court1.index
        end
      end

      context 'custom name' do
        before(:each) do
          court1.custom_name = 'custom'
        end

        it 'finds next available index 1, ignoring sport and type' do
          expect(subject.first).to eq 1
        end
      end
    end
  end

  describe '#connect_venue' do
    let(:venue1) { create :venue }
    let(:venue2) { create :venue }
    let(:venue3) { create :venue }

    it 'sets connected venue id for both venues' do
      venue1.connect_venue(venue2)

      expect(venue1.reload.connected_venue_id).to eq venue2.reload.id
      expect(venue2.connected_venue_id).to eq venue1.id
    end

    it 'does not set connected venue id for invalid venue' do
      venue1.connect_venue('not a venue')

      expect(venue1.reload.connected_venue_id).to eq nil
      expect(venue2.reload.connected_venue_id).to eq nil
    end

    it 'does not connect venue if already connected' do
      venue1.connect_venue(venue2)
      venue1.connect_venue(venue3)

      expect(venue1.reload.connected_venue_id).to eq venue2.reload.id
      expect(venue2.connected_venue_id).to eq venue1.id
    end
  end

  describe '#disconnect_venue' do
    let(:venue1) { create :venue }
    let(:venue2) { create :venue }

    it 'sets connected venue id to nil for both venues' do
      venue1.connect_venue(venue2)
      expect(venue1.reload.connected_venue_id).to eq venue2.reload.id

      venue1.disconnect_venue

      expect(venue1.reload.connected_venue_id).to eq nil
      expect(venue2.reload.connected_venue_id).to eq nil
    end
  end

  describe '#unavailable_slots(sport, start_time, end_time)' do
    subject{ venue.unavailable_slots(sport, start_time, end_time) }

    let!(:venue) { create :venue }
    let!(:court1) { create :court, :with_prices, venue: venue }
    let!(:court2) { create :court, :with_prices, venue: venue }
    let(:sport) { court1.sport_name }

    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).beginning_of_day } }
    let(:end_time) { in_venue_tz { start_time.advance(days: 6).end_of_day } }

    context 'when one court is not taken' do
      let!(:reservation) { create :reservation, court: court1, start_time: start_time.at_noon }

      it 'does not return unavailable slots' do
        expect(subject).to be_empty
      end
    end

    context 'when both courts taken' do
      let!(:reservation1) { create :reservation, court: court1, start_time: start_time.at_noon }
      let!(:reservation2) { create :reservation, court: court2, start_time: start_time.at_noon }

      it 'returns unavailable slot for the whole reservation' do
        expect(subject).to include({ start: reservation1.start_time, end: reservation1.end_time})
      end
    end

    context 'when both courts taken with partially overlapping reservations' do
      let!(:reservation1) {
        create :reservation, court: court1, start_time: start_time.at_noon }
      let!(:reservation2) {
        create :reservation, court: court2, start_time: start_time.at_noon + 30.minutes }

      it 'returns unavailable slot for the overlapping part' do
        expect(subject).to include({ start: start_time.at_noon + 30.minutes,
                                       end: start_time.at_noon + 60.minutes })
      end
    end
  end

  describe 'company state when venue is viewable' do
    let!(:admin) { create :admin, admin_ssn: ssn }
    let!(:company) { create :company, company_tax_id: tax_id, admins: [admin] }
    let(:tax_id) { 'FI2381233' }
    let(:ssn) { '311280-888Y' }

    let!(:venue) { create :venue, :with_courts, :with_photos, company: company, status: :hidden }
    subject { venue.update_attributes status: Venue.statuses[:searchable] }

    it 'allows to change venue status to searchable' do
      is_expected.to be_truthy
    end

    context 'when company is not ready yet' do
      let(:tax_id) { '' }

      it 'does not allow to change venue status' do
        is_expected.to be_falsey
      end
    end

    context 'when admin is not ready yet' do
      let(:ssn) { '' }

      it 'does not allow to change venue status' do
        is_expected.to be_falsey
      end
    end
  end
end
