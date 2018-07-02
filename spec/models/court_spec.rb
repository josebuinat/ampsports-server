require 'rails_helper'

describe Court do
  context "Court Sharing" do
    let!(:venue) { create :venue }
    let!(:tennis_court_1) { create :court, sport_name: :tennis, venue: venue }
    let!(:squash_court_1) { create :court, sport_name: :squash, venue: venue }
    let!(:squash_court_2) { create :court, sport_name: :squash, venue: venue }

    context "create shared courts and reservations" do
      before do
        tennis_court_1.shared_courts << squash_court_1
        tennis_court_1.shared_courts << squash_court_2
      end

      it "should create shared_courts" do
        expect(tennis_court_1.shared_courts.to_a).to eq [squash_court_1, squash_court_2]
      end

      it "should create reciprocal shared_court relationship" do
        expect(squash_court_1.shared_courts.to_a).to eq [tennis_court_1]
        expect(squash_court_2.shared_courts.to_a).to eq [tennis_court_1]
        expect(CourtConnector.count).to eq(4)
      end

      it "should not allow sharing with same court" do
        expect {tennis_court_1.shared_courts << tennis_court_1}.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "overlapping reservations" do
        let!(:tennis_reservation){ create :reservation, court: tennis_court_1 }

        it "should not allow shared court overlapping reservation" do
          tennis_court_1.shared_courts.each do |court|
            squash_reservation = build(:reservation,
                                       court: court,
                                       start_time: tennis_reservation.start_time
            )

            expect(squash_reservation.valid?).to be_falsy
            expect(squash_reservation.errors).to include(:overlapping_reservation)
          end
        end
      end
    end

    context "Remove court sharing" do
      before do
        tennis_court_1.shared_courts << squash_court_1
        tennis_court_1.shared_courts << squash_court_2
        tennis_court_1.shared_courts.destroy(squash_court_1)
      end

      it "should remove reciprocal shared court" do
        expect(tennis_court_1.shared_courts).not_to include(squash_court_1)
        expect(squash_court_1.shared_courts).not_to include(tennis_court_1)
      end
    end
  end

  context 'Price for timeslot' do
    let!(:court) { create :court }
    let(:start_time) { Time.current.advance(weeks: 2).beginning_of_week.at_noon }
    let(:end_time) { start_time + 120.minutes }

    describe '#has_price?' do
      let!(:price) { create :price, courts: [court],
                                     start_time: price_start_time,
                                     end_time: price_end_time,
                                     monday: price_on_monday,
                                     tuesday: price_on_tuesday }
      let(:price_start_time) { start_time - 1.minutes }
      let(:price_end_time) { end_time + 1.minutes }
      let(:price_on_monday) { true }
      let(:price_on_tuesday) { false }

      it 'should return true' do
        expect(court.has_price?(start_time, end_time)).to be_truthy
      end

      context 'when price for other day' do
        let(:price_on_monday) { false }
        let(:price_on_tuesday) { true }

        it 'should return false' do
          expect(court.has_price?(start_time, end_time)).to be_falsy
        end
      end

      context 'when price exactly covers timeslot' do
        let(:price_start_time) { start_time }
        let(:price_end_time) { end_time }

        it 'should return true' do
          expect(court.has_price?(start_time, end_time)).to be_truthy
        end
      end

      context 'when price does not cover timeslot' do
        let(:price_start_time) { start_time + 1.minutes }
        let(:price_end_time) { end_time - 1.minutes }

        it 'should return false' do
          expect(court.has_price?(start_time, end_time)).to be_falsey
        end
      end

      context 'when price does not cover beginning' do
        let(:price_start_time) { start_time + 1.minutes }
        let(:price_end_time) { end_time }

        it 'should return false' do
          expect(court.has_price?(start_time, end_time)).to be_falsey
        end
      end

      context 'when price does not cover ending' do
        let(:price_start_time) { start_time }
        let(:price_end_time) { end_time - 1.minutes }

        it 'should return false' do
          expect(court.has_price?(start_time, end_time)).to be_falsey
        end
      end

      context 'when 3 prices cover timeslot back to back' do
        let(:price_start_time) { start_time }
        let(:price_end_time) { start_time + 60.minutes }
        let!(:price2) { create :price, courts: [court],
                                       start_time: start_time + 61.minutes,
                                       end_time: start_time + 90.minutes,
                                       monday: true }
        let!(:price3) { create :price, courts: [court],
                                       start_time: start_time + 91.minutes,
                                       end_time: end_time,
                                       monday: true }
        it 'should return true' do
          expect(court.has_price?(start_time, end_time)).to be_truthy
        end
      end

      context 'when 3 prices cover timeslot back to back' do
        let(:price_start_time) { start_time }
        let(:price_end_time) { start_time + 59.minutes }
        let!(:price2) { create :price, courts: [court],
                                       start_time: end_time - 59.minutes,
                                       end_time: end_time,
                                       monday: true }

        it 'should return false if 2 prices not cover middle' do
          expect(court.has_price?(start_time, end_time)).to be_falsy
        end
      end
    end

    describe '#price_at' do
      let!(:price1) { create :price, price: 10,
                                    start_time: price1_start_time,
                                    end_time: price1_end_time,
                                    monday: true,
                                    courts: [court] }

      let(:price1_start_time) { start_time }
      let(:price1_end_time) { start_time + 60.minutes }

      context 'with second price' do
        let!(:price2) { create :price, price: 20,
                                      start_time: price2_start_time,
                                      end_time: price2_end_time,
                                      monday: true,
                                      courts: [court] }
        let(:price2_start_time) { start_time + 60.minutes }
        let(:price2_end_time) { start_time + 180.minutes }

        it 'should correctly sum applied prices for hour mark timeslots' do
          expect(court.price_at(start_time, start_time + 60.minutes )).to eq price1.price
          expect(court.price_at(start_time, start_time + 120.minutes)).to eq (price1.price + price2.price)
          expect(court.price_at(start_time, start_time + 180.minutes)).to eq (price1.price + price2.price * 2)
          expect(court.price_at(start_time + 60.minutes , start_time + 120.minutes)).to eq price2.price
          expect(court.price_at(start_time + 120.minutes , start_time + 180.minutes)).to eq price2.price
        end

        context 'for half hout timeslots' do
          let(:price1_start_time) { start_time - 60.minutes }
          let(:price2_end_time) { start_time + 280.minutes }

          it 'should correctly sum applied prices for halfhour mark timeslots' do
            expect(court.price_at(start_time - 30.minutes, start_time + 90.minutes )).to eq (price1.price*1.5 + price2.price*0.5)
            expect(court.price_at(start_time + 30.minutes, start_time + 90.minutes )).to eq (price1.price*0.5 + price2.price*0.5)
            expect(court.price_at(start_time + 30.minutes, start_time + 150.minutes)).to eq (price1.price*0.5 + price2.price*1.5)
          end
        end
      end

      context 'with discount' do
        let(:discount) { build :discount, venue: court.venue }

        it 'should apply discount' do
          expect(court.price_at(start_time, start_time + 60.minutes, discount)).to eq (price1.price / 2)
        end

        context 'with fixed price discount' do
          let(:discount) { build :discount, venue: court.venue, value: 135, method: :fixed_price }

          it 'should apply fixed price discount for 1 hour' do
            expect(court.price_at(start_time, start_time + 60.minutes, discount)).to eq 135
          end

          it 'should apply double fixed price discount for 2 hour' do
            expect(court.price_at(start_time, start_time + 120.minutes, discount)).to eq 270
          end
        end
      end
    end

    describe '#available_on?' do
      let!(:court) { create :court, :with_prices }
      let(:venue) { court.venue }
      let(:start_time) { in_venue_tz { DateTime.current.tomorrow.change(hour: 12, minute: 0) } }
      let(:end_time) { in_venue_tz { DateTime.current.tomorrow.change(hour: 13, minute: 0) } }
      let(:time_frame) { TimeFrame.new(start_time, end_time) }
      subject { in_venue_tz { court.available_on?(time_frame) } }

      context 'when it is totally free' do
        it { is_expected.to be_truthy }
      end

      context 'when time frame is equal to the other booking' do
        let!(:reservation) { create :reservation,
                                    start_time: start_time,
                                    end_time: end_time,
                                    reselling: reselling,
                                    court: court
        }
        let(:reselling) { false }

        it { is_expected.to be_falsey }

        context 'when reservation is reselling' do
          let(:reselling) { true }
          it { is_expected.to be_truthy }
        end
      end

      context 'when there is a partial overlap' do
        let!(:reservation) { create :reservation,
                                    start_time: start_time - 30.minutes,
                                    end_time: end_time - 30.minutes,
                                    reselling: reselling,
                                    court: court
        }
        let(:reselling) { false }

        it { is_expected.to be_falsey }

        context 'when reservation is reselling' do
          let(:reselling) { true }
          # no partial overlap reselling is ok
          it { is_expected.to be_falsey }
        end
      end
    end

    describe 'available_times' do
      context 'when there is a booking' do
        let!(:court) { create :court, :with_prices }
        let(:datetime) { Date.tomorrow.to_datetime.in_time_zone }
        let(:reservation_start_time) { datetime.change(hour: 9, minute: 0) }
        let(:reservation_end_time) { datetime.change(hour: 10, minute: 0) }
        let(:expected_time) { datetime.change(hour: 17, minute: 0) }
        let(:reservation) { create :reservation,
                                   start_time: reservation_start_date,
                                   end_time: reservation_end_time,
                                   court: court
        }
        subject { court.available_times(60, Date.tomorrow).map(&:starts) }

        it 'does not block further available times' do
          is_expected.to include expected_time
        end
      end
    end
  end

  context 'name index' do
    let(:venue) { create(:venue, :with_courts) }
    let(:new_court) { create :court, venue: venue}

    it 'should set indexes for created courts' do
      expect(new_court.index).to eq venue.reload.courts.count
    end
  end

  describe '#payment_skippable' do
    let(:court) { create :court, venue: venue, payment_skippable: true }
    let(:venue) { create :venue, company: company }

    context 'with US venue' do
      let(:company) { create :usa_company }

      it 'ignores setting and returns false' do
        expect(court).not_to be_payment_skippable
      end
    end

    context 'with Finnish venue' do
      let(:company) { create :company }

      it 'uses setting and returns true' do
        expect(court).to be_payment_skippable
      end
    end
  end
end
