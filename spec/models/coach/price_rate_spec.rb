require 'rails_helper'

RSpec.describe Coach::PriceRate, type: :model do
  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_users, company: company }
  let(:user) { venue.users.first }
  let!(:coach) { create :coach, company: company }

  context 'validations' do
    subject{ price_rate }
    let(:price_rate) { build :coach_price_rate, coach: coach, venue: venue }

    describe "#rate" do
      context "validate presence" do
        it "adds error when absent" do
          price_rate.rate = nil

          is_expected.not_to be_valid
          expect(subject.errors).to include(:rate)
        end

        it "is valid when present" do
          is_expected.to be_valid
        end
      end
    end

    describe '#validate_conflicts' do
      subject{ new_price_rate }
      let!(:price_rate) { create :coach_price_rate, coach: coach, venue: venue }
      let(:new_price_rate) {
        build :coach_price_rate, coach: coach,
                                  venue: new_price_rate_venue,
                                  sport_name: new_price_rate_sport,
                                  start_time: new_price_rate_start,
                                  end_time: new_price_rate_end
      }
      let(:new_price_rate_sport) { 'tennis' }
      let(:new_price_rate_venue) { venue }
      let(:new_price_rate_start) { price_rate.start_time }
      let(:new_price_rate_end) { price_rate.end_time }

      context 'with overlapping time' do
        context 'with other venue' do
          let(:new_price_rate_venue) { create :venue }

          it { is_expected.to be_valid }
        end

        context 'with other sport' do
          let(:new_price_rate_sport) { 'squash' }

          it { is_expected.to be_valid }
        end

        context 'with matching values' do
          it { is_expected.not_to be_valid }
        end

        context 'with overlapped start' do
          let(:new_price_rate_start) { price_rate.end_time - 1.minutes }
          let(:new_price_rate_end) { price_rate.end_time + 59.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'with overlapped end' do
          let(:new_price_rate_start) { price_rate.start_time - 59.minutes }
          let(:new_price_rate_end) { price_rate.start_time + 1.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'when wrapped by longer price rate' do
          let(:new_price_rate_start) { price_rate.start_time + 10.minutes }
          let(:new_price_rate_end) { price_rate.end_time - 10.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end

        context 'when wrapping shorter price rate' do
          let(:new_price_rate_start) { price_rate.start_time - 10.minutes }
          let(:new_price_rate_end) { price_rate.end_time + 10.minutes }

          it 'adds error' do
            is_expected.not_to be_valid
            expect(subject.errors).to include(:start_time)
          end
        end
      end

      context 'with not overlapping price rate' do
        context 'with earlier price rate' do
          let(:new_price_rate_start) { price_rate.end_time + 1.minutes }
          let(:new_price_rate_end) { price_rate.end_time + 61.minutes }

          it { is_expected.to be_valid }
        end

        context 'with later price rate' do
          let(:new_price_rate_start) { price_rate.start_time - 61.minutes }
          let(:new_price_rate_end) { price_rate.start_time - 1.minutes }

          it { is_expected.to be_valid }
        end
      end

      context 'with back-to-back price rate' do
        context 'when after' do
          let(:new_price_rate_start) { price_rate.end_time }
          let(:new_price_rate_end) { price_rate.end_time + 60.minutes }

          it { is_expected.to be_valid }
        end

        context 'when before' do
          let(:new_price_rate_start) { price_rate.start_time - 60.minutes }
          let(:new_price_rate_end) { price_rate.start_time }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '#break_into_unavailable_times' do
    let(:start_time) { 1.day.since.noon }
    let(:end_time) { 5.day.since.noon }
    let(:scope) { coach.price_rates.for_venue(venue).for_sport('all').overlapping(start_time, end_time) }
    subject { described_class.break_into_unavailable_times(scope, start_time, end_time) }

    let!(:ignored_price_rate) { create :coach_price_rate, coach: coach, venue: venue,
      start_time: 8.days.since, end_time: 9.days.since }

    context 'with slice within boundaries' do
      # slice from beginning
      let!(:price_rate_1) { create :coach_price_rate, coach: coach, venue: venue,
        start_time: Time.now, end_time: 1.day.since.noon + 2.hours }
      # slice a day
      let!(:price_rate_2) { create :coach_price_rate, coach: coach, venue: venue,
        start_time: 2.days.since.noon, end_time: 3.day.since.noon }
      # slice few hours
      let!(:price_rate_3) { create :coach_price_rate, coach: coach, venue: venue,
        start_time: 3.days.since.noon + 1.hour, end_time: 3.day.since.noon + 3.hours }
      # slice from end
      let!(:price_rate_4) { create :coach_price_rate, coach: coach, venue: venue,
        start_time: 5.days.since.noon - 3.hours, end_time: 5.day.since.noon + 5.hours }

      it 'works' do
        is_expected.to match_array([
          [price_rate_1.end_time, price_rate_2.start_time],
          [price_rate_2.end_time, price_rate_3.start_time],
          [price_rate_3.end_time, price_rate_4.start_time],
        ])
      end
    end

    context 'when boundaries are free' do
      let!(:price_rate) { create :coach_price_rate, coach: coach, venue: venue,
        start_time: 2.days.since.noon, end_time: 3.day.since.noon }

      it 'works' do
        is_expected.to match_array([
          [start_time, price_rate.start_time],
          [price_rate.end_time, end_time],
        ])
      end
    end
  end

end
