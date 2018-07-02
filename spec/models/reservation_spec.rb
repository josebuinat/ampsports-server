require "rails_helper"
require 'stripe_mock'

describe Reservation do
  before(:all) { @venue_for_timezone = build :venue }

  before do
    @old_timezone = Time.zone
    Time.zone = @venue_for_timezone.timezone
  end

  after do
    Time.zone = @old_timezone
  end

  context "creation and validations" do
    let(:reservation) { build :reservation }

    it "should save default reservation" do
      r = create :reservation

      expect(r.persisted?).to be_truthy
    end

    context "#participants" do
      it "should support participating users" do
        participant = create :user
        reservation.participants = [participant]

        expect(reservation.participants).to eq [participant]
      end

      it "should allow reservation owner as participant" do
        reservation.participants = [reservation.user]
        expect(reservation).to be_valid
      end
    end

    describe "#user" do
      context "validate presence" do
        it "should add error when absent" do
          reservation.user = nil

          reservation.valid?
          expect(reservation.errors).to include(:user)
        end

        it "should be valid when present" do
          expect(reservation).to be_valid
        end
      end
    end

    describe "#court" do
      context "validate presence" do
        it "should add error when absent" do
          reservation.court = nil

          reservation.valid?
          expect(reservation.errors).to include(:court)
        end

        it "should be valid when present" do
          expect(reservation).to be_valid
        end
      end
    end

    describe "#price" do
      context "validate presence" do
        it "should add error when absent" do
          reservation.price = nil

          reservation.valid?
          expect(reservation.errors).to include(:price)
        end

        it "should be valid when present" do
          expect(reservation).to be_valid
        end
      end

      context "validate value" do
        it "should be numerical" do
          reservation.price = 'a'

          expect(reservation).not_to be_valid
        end

        it "should be greater or equal to 0" do
          reservation.price = -1

          expect(reservation).not_to be_valid

          reservation.price = 0

          expect(reservation).to be_valid
        end
      end
    end

    describe "#start_time" do
      context "validate presence" do
        it "should add error when absent" do
          reservation.start_time = nil

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when present" do
          expect(reservation).to be_valid
        end
      end
    end

    describe "#end_time" do
      context "validate presence" do
        it "should add error when absent" do
          reservation.end_time = nil

          reservation.valid?
          expect(reservation.errors).to include(:end_time)
        end

        it "should be valid when present" do
          expect(reservation).to be_valid
        end
      end

      context "validate timings" do
        it "should not be less than start_time" do
          reservation.end_time = reservation.start_time.advance(days: -1)

          reservation.valid?
          expect(reservation.errors).to include(:end_time)
        end

        it "should not be same as start_time" do
          reservation.end_time = reservation.start_time

          expect(reservation).not_to be_valid
          expect(reservation.errors).to include(:end_time)
        end
      end
    end

    describe "#in_the_future" do
      before(:each) do
        allow(Time).to receive(:current).and_return(Time.current.at_noon)
      end

      context "for user" do
        it "should add error when in the past" do
          reservation = build :reservation, start_time: Time.current.advance(seconds: -1).utc

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when in the future" do
          reservation = build :reservation, start_time: Time.current.advance(seconds: 1).utc

          expect(reservation).to be_valid
        end
      end

      context "for admin" do
        it "should be valid when in the past" do
          reservation = build :reservation, start_time: Time.current.advance(seconds: -1).utc, booking_type: :admin

          expect(reservation).to be_valid
        end

        it "should be valid when in the future" do
          reservation = build :reservation, start_time: Time.current.advance(seconds: 1).utc, booking_type: :admin

          expect(reservation).to be_valid
        end
      end
    end

    describe "#no_overlapping_reservations (#overlapped?)" do
      let(:reserved) { create :reservation }
      let(:reservation) { build :reservation, court: reserved.court }

      context "overlapping reservation" do
        it "should add error when has overlapped start" do
          reservation.start_time = reserved.start_time + 50.minutes
          reservation.end_time   = reserved.end_time + 50.minutes

          reservation.valid?
          expect(reservation.errors).to include(:overlapping_reservation)
        end

        it "should add error when has overlapped end" do
          reservation.start_time = reserved.start_time - 50.minutes
          reservation.end_time   = reserved.end_time - 50.minutes

          reservation.valid?
          expect(reservation.errors).to include(:overlapping_reservation)
        end

        it "should add error when wrapped by longer reservation" do
          reservation.start_time = reserved.start_time + 15.minutes
          reservation.end_time   = reserved.end_time - 15.minutes

          reservation.valid?
          expect(reservation.errors).to include(:overlapping_reservation)
        end

        it "should add error when wrapping shorter reservation" do
          reservation.start_time = reserved.start_time - 30.minutes
          reservation.end_time   = reserved.end_time + 30.minutes

          reservation.valid?
          expect(reservation.errors).to include(:overlapping_reservation)
        end
      end

      context "adjacent and near reservation" do
        it "should be valid when touching reserved end" do
          reservation.start_time = reserved.end_time
          reservation.end_time   = reserved.end_time + 60.minutes

          expect(reservation).to be_valid
        end

        it "should be valid when touching reserved start" do
          reservation.start_time = reserved.start_time - 60.minutes
          reservation.end_time   = reserved.start_time

          expect(reservation).to be_valid
        end

        it "should be valid when not overlapped by earlier reservation" do
          reservation.start_time = reserved.end_time + 30.minutes
          reservation.end_time   = reserved.end_time + 90.minutes

          expect(reservation).to be_valid
        end

        it "should be valid when not overlapped by later reservation" do
          reservation.start_time = reserved.start_time - 90.minutes
          reservation.end_time   = reserved.start_time - 30.minutes

          expect(reservation).to be_valid
        end
      end

      context "reservation with overlapping time but not overlapping params" do
        it "should be valid when overlapping reservation from different court" do
          reservation.start_time = reserved.start_time
          reservation.end_time   = reserved.end_time
          reservation.court = create(:court)

          expect(reservation).to be_valid
        end

        it "should be valid when overlapping itself" do
          expect(reserved).to be_valid
        end
      end
    end

    describe "#not_on_holiday" do
      let(:holiday_start_time) { DateTime.current.advance(weeks: 1).change(hour: 6, minute: 0, second: 0) }

      context "validate closed court on holiday" do
        let(:court) { create :court }
        let(:reservation) { build :reservation, court: court }
        let!(:holiday) { create :holiday, start_time: holiday_start_time, courts: [court] }

        it "should add error when court closed on holiday" do
          reservation.start_time = holiday_start_time.change(hour: 10, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:Court)
        end

        it "should be valid when court not on holiday" do
          reservation.start_time = holiday_start_time.advance(days: 2).change(hour: 10, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end

      context "validate closed venue on holiday" do
        let(:court) { create :court }
        let(:reservation) { build :reservation, court: court }
        let!(:holiday) { create :holiday, start_time: holiday_start_time, courts: [court] }

        it "should add error when venue closed on holiday" do
          reservation.start_time = holiday_start_time.change(hour: 10, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:Court)
        end

        it "should be valid when venue not on holiday" do
          reservation.start_time = holiday_start_time.advance(days: 2).change(hour: 10, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end

      context "validate venue closed time" do
        let(:day) { DateTime.current.advance(weeks: 1) }
        let(:opening_hour) { reservation.court.venue.opening_local(day).hour }
        let(:closing_hour) { reservation.court.venue.closing_local(day).hour }

        it "should add error if too early" do
          reservation.start_time = day.change(hour: opening_hour - 1, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:Court)
        end

        it "should add error if too late" do
          reservation.start_time = day.change(hour: closing_hour, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:Court)
        end

        it "should be valid if within time" do
          reservation.start_time = day.change(hour: opening_hour + 1, minute: 0, second: 0)
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation.end_time.hour).to be < closing_hour
          expect(reservation).to be_valid
        end
      end
    end

    describe "#duration_policy" do
      let(:court) { create :court, duration_policy: :two_hour }
      let(:reservation) { build :reservation, court: court }

      context "validate reseration duration" do
        it "should add error when duration is less than court policy" do
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:duration_policy)
        end

        it "should be valid when duration equals court policy" do
          reservation.end_time   = reservation.start_time + 2.hours

          expect(reservation).to be_valid
        end

        it "should be valid when duration is greater than court policy" do
          reservation.end_time   = reservation.start_time + 3.hours

          expect(reservation).to be_valid
        end
      end
    end

    describe "#start_time_policy" do
      context "when court has any time policy" do
        let(:court) { create :court, start_time_policy: :any_start_time }
        let(:reservation) { build :reservation, court: court }

        it "should be valid when start at odd time" do
          reservation.start_time = reservation.start_time + 13.minutes
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end

      context "when court has hour policy" do
        let(:court) { create :court, start_time_policy: :hour_mark }
        let(:reservation) { build :reservation, court: court }

        it "should add error when start time not at start of hour" do
          reservation.start_time = reservation.start_time.at_noon + 30.minutes
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when start time at start of hour" do
          reservation.start_time = reservation.start_time.at_noon
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end

      context "when court has quarter hour policy" do
        let(:court) { create :court, start_time_policy: :quarter_hour_mark }
        let(:reservation) { build :reservation, court: court }

        it "should add error when start time not at the quarter of hour" do
          reservation.start_time = reservation.start_time.at_noon
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when start time at second quarter of hour" do
          reservation.start_time = reservation.start_time.at_noon + 15.minutes
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end

        it "should be valid when start time at fourth quarter of hour" do
          reservation.start_time = reservation.start_time.at_noon + 45.minutes
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end

      context "when court has half hour policy" do
        let(:court) { create :court, start_time_policy: :half_hour_mark }
        let(:reservation) { build :reservation, court: court }

        it "should add error when start time not at half of hour" do
          reservation.start_time = reservation.start_time.at_noon
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when start time at half of hour" do
          reservation.start_time = reservation.start_time.at_noon + 30.minutes
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end
    end

    describe "#date_limit_policy" do
      let(:court) { create :court }
      let(:start_time) { Time.use_zone(court.venue.timezone) { DateTime.current.change(hour: 12, minute: 0, second: 0) } }
      let(:reservation) { build :reservation,
                                court: court,
                                start_time: start_time }
      let(:days) { reservation.court.venue.booking_ahead_limit }

      context "validate venue booking ahead date limit" do
        it "should add error when date after booking_ahead_limit" do
          reservation.start_time = reservation.start_time + (days + 1).days
          reservation.end_time   = reservation.start_time + 1.hours

          reservation.valid?
          expect(reservation.errors).to include(:start_time)
        end

        it "should be valid when date before booking_ahead_limit" do
          reservation.start_time = reservation.start_time + (days - 1).days
          reservation.end_time   = reservation.start_time + 1.hours

          expect(reservation).to be_valid
        end
      end
    end

    describe "#court_active" do
      context "validate if court is open" do
        it 'should add error when court is closed(not active)' do
          reservation.court.update_attribute(:active, false)

          reservation.valid?
          expect(reservation.errors).to include(:court)
        end

        it 'should be valid when court is open' do
          reservation.court.update_attribute(:active, true)

          expect(reservation).to be_valid
        end
      end
    end

    describe "#booking_limits" do
      let!(:venue) { create :venue, :with_courts }
      let(:court) { venue.courts.first }
      let!(:other_user) { create :user, venues: [venue] }
      let!(:existing_reservation) { create :reservation, :two_hours, court: court }
      let(:reservation) {
        build :reservation, :two_hours, court: court, user: user, start_time: start_time
      }
      let(:user) { existing_reservation.user }
      let(:start_time) { existing_reservation.end_time }

      context "validate consecutive bookable hours" do
        context 'when reservations are consecutive' do
          context 'with same user' do
            it "adds an error when booked hours are greater than venue limit" do
              venue.update_attribute(:max_consecutive_bookable_hours, 3)

              error = I18n.t('errors.reservation.end_time.max_consecutive_hours', expected: 3, given: 4)
              expect(reservation).not_to be_valid
              expect(reservation.errors).to include(:end_time)
              expect(reservation.errors[:end_time]).to include(error)
            end

            it "is valid when booked hours are equal to venue limit" do
              venue.update_attribute(:max_consecutive_bookable_hours, 4)

              expect(reservation).to be_valid
            end

            it "is valid when booked hours are less than venue limit" do
              venue.update_attribute(:max_consecutive_bookable_hours, 5)

              expect(reservation).to be_valid
            end
          end

          context 'with different users' do
            let(:user) { other_user }

            it "is valid when booked hours are greater than venue limit" do
              venue.update_attribute(:max_consecutive_bookable_hours, 3)

              expect(reservation).to be_valid
            end
          end
        end

        context 'when reservations are not consecutive' do
          let(:start_time) { existing_reservation.end_time + 1.hours }

          it "is valid when booked hours are greater than venue limit" do
            venue.update_attribute(:max_consecutive_bookable_hours, 3)

            expect(reservation).to be_valid
          end
        end
      end

      context "validate bookable hours per day" do
        context 'with same user' do
          it "adds an error when booked hours are greater than venue limit" do
            venue.update_attribute(:max_bookable_hours_per_day, 3)

            error = I18n.t('errors.reservation.end_time.max_hours_per_day', expected: 3, given: 4)
            expect(reservation).not_to be_valid
            expect(reservation.errors).to include(:end_time)
            expect(reservation.errors[:end_time]).to include(error)
          end

          it "is valid when booked hours are equal to venue limit" do
            venue.update_attribute(:max_bookable_hours_per_day, 4)

            expect(reservation).to be_valid
          end

          it "is valid when booked hours are less than venue limit" do
            venue.update_attribute(:max_bookable_hours_per_day, 5)

            expect(reservation).to be_valid
          end

          context 'when reservations are made on different dates' do
            let(:start_time) { existing_reservation.end_time + 1.days }

            it "is valid when booked hours are greater than venue limit" do
              venue.update_attribute(:max_bookable_hours_per_day, 3)

              expect(reservation).to be_valid
            end
          end
        end

        context 'with different users' do
          let(:user) { other_user }

          it "is valid when booked hours are greater than venue limit" do
            venue.update_attribute(:max_bookable_hours_per_day, 3)

            expect(reservation).to be_valid
          end
        end
      end
    end

    describe '#coach_availability' do
      let(:reservation) { build :reservation, court: court, coaches: coaches }
      let(:coach) { create :coach }
      let(:court) { create :court, :with_prices }

      context 'without coach' do
        let(:coaches) { [] }

        it{ expect(reservation).to be_valid }
      end

      context 'with coach' do
        let(:coaches) { [coach] }

        context 'without price' do
          it 'adds error' do
            expect(reservation).not_to be_valid
            expect(reservation.errors.messages)
              .to include(coach_ids: [I18n.t('errors.coach.unavailable',
                                        name: coach.full_name)])
          end
        end

        context 'with priced coach' do
          let(:coach) { create :coach, :available, for_court: court }

          it 'is valid and can save a reservation with coach' do
            expect(reservation).to be_valid
            expect(reservation.save).to be_truthy
            expect(reservation.reload.coaches).to include coach
          end

          context 'when coach has other reservation ' do
            let(:other_court) { create :court, venue: court.venue }
            let!(:other_reservation) {
              create :reservation, coaches: [coach], court: other_court
            }

            it 'adds error' do
              expect(reservation).not_to be_valid
              expect(reservation.errors.messages)
                .to include(coach_ids: [I18n.t('errors.coach.unavailable',
                                          name: coach.full_name)])
              expect(reservation.errors).not_to include(:overlapping_reservation)
            end
          end

          context 'when updating reseervation timeslot' do
            subject{ reservation.update(end_time: reservation.end_time.advance(minutes: 30)) }
            before{ reservation.save }

            it 'updates without problem' do
              expect(reservation).to be_persisted
              expect(subject).to be_truthy
            end

            context 'when court changed to unavailable for coach' do
              subject{ reservation.update(court: other_court) }
              let(:other_court) { create :court, venue: court.venue, sport_name: :squash }

              it 'does not update with coach error' do
                expect(reservation).to be_persisted
                expect(subject).to be_falsey
                expect(reservation.errors.messages)
                  .to include(coach_ids: [I18n.t('errors.coach.unavailable',
                                                    name: coach.full_name)])
              end
            end
          end
        end
      end

      context 'with coach from group' do
        let(:reservation) { build :reservation, user: group, court: court }
        let!(:venue) { create :venue, :with_courts }
        let(:court) { venue.courts.first }
        let(:group) { create :group, venue: venue, coaches: [coach] }

        context 'without price' do
          let(:coach) { create :coach }

          it 'is valid and saves resevation without coach' do
            expect(reservation).to be_valid
            reservation.save
            expect(reservation.reload.coaches).to be_none
          end
        end

        context 'with priced coach' do
          let(:coach) { create :coach, :available, for_court: court }

          it 'is valid and saves coach to resevation' do
            expect(reservation).to be_valid
            reservation.save
            expect(reservation.reload.coach_ids).to match_array group.coach_ids
          end
        end
      end

      context 'with owner coach' do
        let(:reservation) { build :reservation, user: owner_coach,
                                                court: court,
                                                coaches: coaches }
        let(:court) { create :court, :with_prices }
        let(:coaches) { [] }

        context 'with unavailable owner coach' do
          let(:owner_coach) { create :coach }

          it 'adds error' do
            expect(reservation).not_to be_valid
            expect(reservation.errors.messages)
              .to include(coach_ids: [I18n.t('errors.coach.unavailable',
                                              name: owner_coach.full_name)])
          end
        end

        context 'with available owner coach' do
          let(:owner_coach) { create :coach, :available, for_court: court }

          it 'is valid and can save a reservation with owner as a coach' do
            expect(reservation).to be_valid
            expect(reservation.save).to be_truthy
            expect(reservation.reload.coaches).to include owner_coach
          end

          context 'with available other coach' do
            let(:other_coach) { create :coach, :available, for_court: court }
            let(:coaches) { [other_coach] }

            it 'is valid and can save a reservation with both coaches' do
              expect(reservation).to be_valid
              expect(reservation.save).to be_truthy
              expect(reservation.reload.coaches).to match_array [owner_coach, other_coach]
            end
          end
        end
      end
    end

    describe 'shared courts and allow_overlapping_resell' do
      let!(:venue) { create :venue, allow_overlapping_resell: allow_overlapping_resell }
      let(:allow_overlapping_resell) { false }
      let!(:small_court_1) { create :court, :with_prices, venue: venue, sport_name: :badminton }
      let!(:small_court_2) { create :court, :with_prices, venue: venue, sport_name: :badminton }
      let!(:big_court) { create :court, :with_prices, venue: venue, sport_name: :tennis,
        shared_courts: [small_court_1, small_court_2] }
      let!(:membership) { create :membership, :with_reservations, venue: venue }
      let!(:other_user) { create :user }
      let(:big_reservation) { membership.reservations.last.tap { |x| x.update!(reselling: true) } }
      subject(:new_reservation) do
        Reservation.new(court: small_court_1, user: other_user, price: 10,
          start_time: big_reservation.start_time, end_time: big_reservation.end_time)
      end

      it 'does not allow to resell small reservation' do
        expect(new_reservation).to be_invalid
        expect(new_reservation.errors).to have_key :overlapping_reservation
      end

      it 'does not change anything' do
        expect { new_reservation.save }.not_to change { Reservation.count }
      end

      context 'when allow partial resell' do
        let(:allow_overlapping_resell) { true }

        it 'allows to resell smaller reservations' do
          expect(new_reservation).to be_valid
        end

        # because badminton is played on that tennis court now, cannot book tennis anymore!
        it 'cancels the original reservation' do
          # we save one reservation and expect one to be gone, so to change by zero
          expect { new_reservation.save }.to change { big_reservation.reload.inactive }.from(false).to(true)
        end
      end
    end
  end

  context "scopes" do
    describe "#invoiceable" do
      let!(:reservation_paid) { create :reservation, payment_type: :paid }
      let!(:reservation_billed) { create :reservation,
                                         billing_phase: Reservation.billing_phases[:billed] }
      let!(:reservation_semi_paid) { create :reservation,
                                            price: 22,
                                            amount_paid: 12,
                                            payment_type: :semi_paid }
      let!(:reservation_zero_priced) { create :reservation,
                                              price: 0,
                                              payment_type: :unpaid}
      let!(:reservation_unpaid) { create :reservation }

      it "should include all not paid, not billed invoices" do
        expect(Reservation.invoiceable.count).to eq(2)
      end

      it "should not include paid or billed reservations" do
        expect(Reservation.count - Reservation.invoiceable.count).to eq(3)
      end
    end

    describe '#with_user' do
      subject{ Reservation.for_user(user_id) }
      let(:participant) { create :user }
      let!(:reservation) { create :reservation, participants: [participant]}
      let!(:other_reservation) { create :reservation }

      context 'with main user' do
        let(:user_id) { reservation.user_id }
        it 'returns correct reservations' do
          is_expected.to match_array [reservation]
          is_expected.not_to include [other_reservation]
        end
      end

      context 'with participant user' do
        let(:user_id) { participant.id }
        it 'returns correct reservations' do
          is_expected.to match_array [reservation]
          is_expected.not_to include [other_reservation]
        end
      end
    end

    describe '#with_coach' do
      subject{ Reservation.for_coach(coach_id) }
      let(:court) { create :court, :with_prices }
      let!(:coach) { create :coach, :available, for_court: court }
      let!(:owner_coach) { create :coach, :available, for_court: court }
      let!(:reservation) { create :reservation, user: owner_coach, coaches: [coach], court: court }
      let!(:other_reservation) { create :reservation }

      context 'with owner coach' do
        let(:coach_id) { owner_coach.id }
        it 'returns correct reservations' do
          is_expected.to match_array [reservation]
        end
      end

      context 'with other coach' do
        let(:coach_id) { coach.id }
        it 'returns correct reservations' do
          is_expected.to match_array [reservation]
        end
      end
    end
  end

  describe '#color' do
    #TODO: test other execution passes
    let (:venue) { create :venue, :with_courts, court_count: 1 }
    let (:court) { venue.courts.first }
    let (:user) { create :user, venues: [venue] }
    let (:colors) { Venue::DEFAULT_COLORS }
    let (:price) { 20 }
    let (:reservation) { create :reservation, user: user, price: price, court: court }

    context 'with guest reservation' do
      let (:user) { create(:guest) }

      it 'returns right color for paid' do
        reservation.update_attributes(amount_paid: price)
        expect(reservation.color).to eq(colors[:guest_paid] || colors[:paid])
      end

      it 'returns right color for non paid reservation' do
        expect(reservation.color).to eq(colors[:guest_unpaid] || colors[:unpaid])
      end
    end

    context 'with non guest reservation' do
      it 'returns right color for paid reservation' do
        reservation.update_attributes(amount_paid: price)
        expect(reservation.color).to eq(colors[:paid])
      end

      it 'returns right color for unpaid reservation' do
        expect(reservation.color).to eq(colors[:unpaid])
      end
    end

    context 'user/discount specific color' do
      let (:specific_color) { "#123456" }

      it 'returns right color for user specific color' do
        reservation.venue.user_colors = [{ user_id: user.id, color: specific_color }]
        expect(reservation.color).to eq(specific_color)
      end

      it 'returns right color for discount specific color' do
        discount = FactoryGirl.create(:discount)
        user.discounts << discount
        reservation.venue.discount_colors = [{ discount_id: discount.id, color: specific_color }]
        expect(reservation.color).to eq(specific_color)
      end
    end

    context 'with coached reservation' do
      let(:coaches_color) { "#653421" }
      let(:specific_color) { "#123456" }
      let(:coach) { create :coach, :available, for_court: court  }
      let(:reservation) { create :reservation, user: user, coaches: [coach], court: court  }

      context 'with unset coach colors' do
        it 'returns color for unpaid reservation' do
          expect(reservation.color).to eq(colors[:unpaid])
        end
      end

      context 'with set general coach color' do
        it 'returns general coach color' do
          reservation.venue.custom_colors = { coached: coaches_color }
          expect(reservation.color).to eq(coaches_color)
        end

        context 'with set per coach color' do
          it 'returns coach specific color' do
            reservation.venue.coach_colors = [{ coach_id: coach.id, color: specific_color }]
            expect(reservation.color).to eq(specific_color)
          end
        end
      end
    end

    context 'with group reservation' do
      let(:group_color) { "#653421" }
      let(:classification_color) { "#123456" }
      let(:group_classification) { create :group_classification }
      let(:group) { create :group, venue: venue, classification: group_classification }
      let(:reservation) { create :reservation, user: group, court: court }

      it 'returns color for unpaid reservation' do
        expect(reservation.color).to eq(colors[:unpaid])
      end

      context 'with set group color' do
        it 'returns group specific color' do
          reservation.venue.group_colors = [{ group_id: group.id, color: group_color }]
          expect(reservation.color).to eq(group_color)
        end

        context 'with set classification color' do
          it 'returns classification specific color' do
            reservation.venue.classification_colors = [
              { classification_id: group_classification.id, color: classification_color }
            ]
            expect(reservation.color).to eq(classification_color)
          end
        end
      end
    end
  end

  describe '#cancel' do
    context "normal reservation" do
      let!(:venue) { create :venue, :with_courts, :with_users }
      let!(:user) { venue.users.first }
      let!(:reservation) { create :reservation, user: user, court: venue.courts.first }

      it 'deactvates reservation' do
        reservation.cancel(user)

        expect(reservation.inactive).to be_truthy
      end

      it 'does not delete reservation' do
        expect{reservation.cancel(user)}.not_to change(Reservation.unscoped, :count)

        expect(Reservation.unscoped.first.id).to eq reservation.id
      end

      context 'invoiced' do
        let!(:invoice) { Invoice.create_for_company(venue.company, user) }

        it 'deletes reservation invoice components' do
          expect(InvoiceComponent.count).to eq 1
          expect(InvoiceComponent.first.reservation).to eq reservation

          reservation.cancel(user)

          expect(InvoiceComponent.count).to eq 0
        end

        it 'recalculates invoice total' do
          expect(invoice.reload.total).to eq reservation.price

          reservation.cancel(user)

          expect(invoice.reload.total).to eq 0
        end
      end
    end

    context "resold reservation" do
      let(:membership) { create :membership }
      let(:resell) { create :reservation,
                            reselling: true,
                            booking_type: :membership,
                            membership: membership,
                            user: membership.user,
                            court: membership.venue.courts.first }
      let(:booking) { build :reservation,
                            court: resell.court,
                            start_time: resell.start_time,
                            end_time: resell.end_time,
                            price: resell.price + 7 }
      let(:reservation) { booking.take_matching_resell }

      before do
        reservation.save
        reservation.reload
      end

      it 'should set user to initial user without deactivating reservation' do
        expect(reservation.user).not_to eq membership.user

        reservation.cancel(reservation.user)
        reservation.reload

        expect(reservation.user).to eq membership.user
        expect(reservation.inactive).to be_falsey
      end
    end

    context 'with refund' do
      subject{ reservation.cancel(user) }

      let!(:venue) { create :venue, :with_courts, :with_users }
      let(:user) { venue.users.first }
      let!(:reservation) { create :reservation, user: user, court: venue.courts.first }

      context 'with card' do
        let(:stripe_helper) { StripeMock.create_test_helper }

        before do
          StripeMock.start
          reservation.charge(stripe_helper.generate_card_token)
          reservation.reload
        end
        after { StripeMock.stop }

        it 'cancels reservation with refund' do
          expect{ subject }.to change{ Reservation.cancelled.count }.by(1)
          cancelled_reservation = Reservation.cancelled.find(reservation.id)
          expect(cancelled_reservation).to be_refunded
          expect(cancelled_reservation.is_paid).to be_falsey
          expect(cancelled_reservation.charge_id).to be_nil
          expect(cancelled_reservation.billing_phase).to eq 'not_billed'
        end
      end

      context 'with game pass' do
        let!(:game_pass) { create :game_pass, :available, user: user, venue: venue }

        before do
          reservation.update(game_pass_id: game_pass.id)
        end

        it 'cancels reservation with refund' do
          expect{ subject }.to change{ Reservation.cancelled.count }.by(1)
                           .and change{ game_pass.reload.remaining_charges }.by(1.0)

          cancelled_reservation = Reservation.cancelled.find(reservation.id)
          expect(cancelled_reservation).to be_refunded
          expect(cancelled_reservation.is_paid).to be_falsey
          expect(cancelled_reservation.game_pass_id).to be_nil
          expect(cancelled_reservation.billing_phase).to eq 'not_billed'
        end
      end
    end
  end

  describe '#charge' do
    subject do
      reservation.charge(stripe_helper.generate_card_token)
      Stripe::Charge.retrieve(reservation.reload.charge_id) if reservation.reload.charge_id
    end

    let(:stripe_helper) { StripeMock.create_test_helper }
    let(:company) { create :company }
    let(:venue) { create :venue, company: company }
    let(:court) { create :court, venue: venue }
    let(:reservation) { create :reservation, court: court, price: price }
    let(:price) { 10.03.to_d }

    before { StripeMock.start }
    after { StripeMock.stop }

    it 'creates a Stripe charge' do
      expect(subject.is_a?(Stripe::Charge)).to be_truthy
      expect(subject.paid).to be_truthy
    end

    it 'marks reservation as paid' do
      expect{ subject }.to change{ reservation.reload.is_paid }.to(true)
                       .and change { reservation.reload.payment_type }.to('paid')
                       .and change { reservation.reload.amount_paid }.to(price)
    end

    context 'with Finnish venue' do
      it 'uses EUR currency' do
        expect(subject.currency).to eq 'eur'
      end

      it 'transfers partial amount to venue with subtracted 0.5% commission' do
        expect(subject.amount).to eq 1003
        venue_amount = (price * (1 - 0.014) - 0.25) * (1 - 0.005)
        expect(subject.destination.amount).to eq (venue_amount * 100).ceil
      end
    end

    context 'with US venue' do
      let(:company) { create :usa_company }

      it 'uses USD currency' do
        expect(subject.currency).to eq 'usd'
      end

      it 'transfers partial amount to venue with subtracted $1 commission' do
        expect(subject.amount).to eq ((price * 1.029 + 0.3) * 1.005 * 100).ceil
        venue_amount = (price * 1.029 + 0.3) * 1.005 - 1
        expect(subject.destination.amount).to eq (venue_amount * 100).ceil
      end

      context 'when resulting venue price is less than commission' do
        let(:price) { 0.54 }

        it 'sends error to Rollbar' do
          expect(Rollbar).to receive(:error).with(
            instance_of(Reservation::ChargeParamsError),
            'Stripe charge failed',
            a_hash_including(reservation_id: reservation.id)
          )

          expect{ subject }.not_to change{ reservation.paid? }
        end
      end
    end

    it 'sends error to Rollbar in case Stripe raises an exception' do
      allow(Stripe::Charge).to receive(:create).and_raise(Stripe::InvalidRequestError.new('message', {}, nil, nil, { error: { message: 'Stripe message'} }))
      expect(Rollbar).to receive(:error).with(
        instance_of(Stripe::InvalidRequestError),
        'Stripe charge failed',
        a_hash_including(reservation_id: reservation.id)
      )
      reservation.charge('stripe_token')
    end
  end

  describe "#conflicting?" do
    subject{ reservation.conflicting?(start_time, end_time) }

    let(:reservation) { build :reservation }
    let(:start_time) { reservation.start_time }
    let(:end_time) { reservation.end_time }

    context "reservation overlapping starts..ends time" do
      context "when overlapping starts" do
        let(:start_time) { reservation.start_time + 50.minutes }
        let(:end_time) { reservation.end_time + 50.minutes }

        it{ is_expected.to be_truthy }
      end

      context "when overlapping ends" do
        let(:start_time) { reservation.start_time - 50.minutes }
        let(:end_time) { reservation.end_time - 50.minutes }

        it{ is_expected.to be_truthy }
      end

      context "when wrapped by starts..ends" do
        let(:start_time) { reservation.start_time - 10.minutes }
        let(:end_time) { reservation.end_time + 10.minutes }

        it{ is_expected.to be_truthy }
      end

      context "when wrapping starts..ends" do
        let(:start_time) { reservation.start_time + 10.minutes }
        let(:end_time) { reservation.end_time - 10.minutes }

        it{ is_expected.to be_truthy }
      end
    end

    context "reservation not overlapping adjacent and near time" do
      context "when touching ends" do
        let(:start_time) { reservation.start_time - 60.minutes }
        let(:end_time) { reservation.start_time }

        it{ is_expected.to be_falsey }
      end

      context "when touching starts" do
        let(:start_time) { reservation.end_time }
        let(:end_time) { reservation.end_time + 60.minutes }

        it{ is_expected.to be_falsey }
      end

      context "when not overlapping and later" do
        let(:start_time) { reservation.start_time - 70.minutes }
        let(:end_time) { reservation.start_time - 10.minutes }

        it{ is_expected.to be_falsey }
      end

      context "when not overlapping and earlier" do
        let(:start_time) { reservation.end_time + 10.minutes }
        let(:end_time) { reservation.end_time + 70.minutes }

        it{ is_expected.to be_falsey }
      end
    end

    describe "reselling reservation" do
      before(:each) do
        reservation.reselling = true
        reservation.venue.update_attribute(:allow_overlapping_resell, false)
      end

      context 'when reselling and matching time' do
        it{ is_expected.to be_falsey }
      end

      context 'when reselling and not matching time' do
        let(:start_time) { reservation.start_time }
        let(:end_time) { reservation.end_time - 1.minutes }

        it{ is_expected.to be_truthy }

        context 'venue.allow_overlapping_resell is true' do
          before(:each) do
            reservation.venue.update_attribute(:allow_overlapping_resell, true)
          end

          it{ is_expected.to be_falsey }
        end
      end
    end
  end

  context "reservations resell" do
    let(:reservation) { build :reservation, reselling: true }

    describe "#take_matching_resell" do
      let!(:venue) { create :venue, :with_courts, :with_users, court_count: 1, user_count: 1 }
      let!(:user) { venue.users.first }
      let!(:court) { venue.courts.first }
      let(:start_time) { Time.current.advance(weeks: 2).change(hour: 10).utc }
      let(:membership) { create :membership,
                                user: user,
                                venue: venue,
                                start_time: start_time,
                                end_time: start_time + 1.weeks }
      let(:resell) { create :reservation,
                            reselling: true,
                            booking_type: :membership,
                            membership: membership,
                            user: user, court: court,
                            start_time: membership.start_time,
                            end_time: membership.start_time + 2.hours
      }
      let(:booking) { build :reservation,
                            court: resell.court,
                            start_time: resell.start_time,
                            end_time: resell.end_time,
                            price: resell.price + 7 }

      context "find matching resell" do
        it 'should return self when reselling reservation with not matching court' do
          booking.court = create :court

          expect(booking.take_matching_resell).to eq booking
        end

        it 'should return self when usual reservation with matching time ' do
          non_resell = create :reservation
          booking = build :reservation, court: non_resell.court
          booking.start_time = non_resell.start_time
          booking.end_time = non_resell.end_time

          expect(booking.take_matching_resell).to eq booking
        end

        context 'venue.allow_overlapping_resell is false' do
          before(:each) do
            booking.venue.update_attribute(:allow_overlapping_resell, false)
          end

          it 'should find reselling reservation with matching time and court' do
            expect(booking.take_matching_resell.id).to eq resell.id
          end

          it 'should return self when reselling reservation with not matching start_time' do
            booking.start_time = resell.start_time + 1.minute

            expect(booking.take_matching_resell).to eq booking
          end

          it 'should return self when reselling reservation with not matching end_time' do
            booking.end_time = resell.end_time + 1.minute

            expect(booking.take_matching_resell).to eq booking
          end
        end

        context 'venue.allow_overlapping_resell is true' do
          before(:each) do
            booking.venue.update_attribute(:allow_overlapping_resell, true)
          end

          it 'should find reselling reservation with matching time' do
            expect(booking.take_matching_resell.id).to eq resell.id
          end

          context "intersecting resell" do
            it "should find reselling with overlapped start" do
              booking.start_time = resell.start_time + 50.minutes
              booking.end_time   = resell.end_time + 50.minutes

              expect(booking.take_matching_resell.id).to eq resell.id
            end

            it "should find reselling with overlapped end" do
              booking.start_time = resell.start_time - 50.minutes
              booking.end_time   = resell.end_time - 50.minutes

              expect(booking.take_matching_resell.id).to eq resell.id
            end

            it "should find reselling wrapped by longer booking" do
              booking.start_time = resell.start_time + 15.minutes
              booking.end_time   = resell.end_time - 15.minutes

              expect(booking.take_matching_resell.id).to eq resell.id
            end

            it "should find reselling wrapping shorter booking" do
              booking.start_time = resell.start_time - 30.minutes
              booking.end_time   = resell.end_time + 30.minutes

              expect(booking.take_matching_resell.id).to eq resell.id
            end
          end

          context "adjacent and near resell" do
            it "should return self when touching resell end" do
              booking.start_time = resell.end_time
              booking.end_time   = resell.end_time + 60.minutes

              expect(booking.take_matching_resell).to eq booking
            end

            it "should return self when touching resell start" do
              booking.start_time = resell.start_time - 60.minutes
              booking.end_time   = resell.start_time

              expect(booking.take_matching_resell).to eq booking
            end

            it "should return self when not overlapping earlier reselling" do
              booking.start_time = resell.end_time + 30.minutes
              booking.end_time   = resell.end_time + 90.minutes

              expect(booking.take_matching_resell).to eq booking
            end

            it "should return self when not overlapping later reselling" do
              booking.start_time = resell.start_time - 90.minutes
              booking.end_time   = resell.start_time - 30.minutes

              expect(booking.take_matching_resell).to eq booking
            end
          end
        end
      end

      context "assign params to takeover ownership" do
        it 'should set :user to new user' do
          expect(booking.user.id).not_to eq resell.user.id
          expect(booking.take_matching_resell.user).to eq booking.user
        end
      end

      context "assign params to make reservation resold and reversible" do
        it 'should set initial membership to previous membership' do
          initial_membership = Membership.find(booking.take_matching_resell.initial_membership_id)
          expect(initial_membership).to eq resell.membership
        end

        it 'should be able to find previous user through initial_membership' do
          initial_membership = Membership.find(booking.take_matching_resell.initial_membership_id)
          expect(initial_membership.user).to eq resell.user
        end
      end

      context "assign params to make resell like usual reservation" do
        it 'should set booking price' do
          expect(booking.price).not_to eq resell.price
          expect(booking.take_matching_resell.price).to eq booking.price
        end

        it 'should set online booking type' do
          expect(booking.take_matching_resell.booking_type).to eq :online.to_s
        end

        it 'should set reselling to false' do
          expect(booking.take_matching_resell.reselling).to be_falsey
        end
      end

      context "assign booking timings" do
        it 'should set booking start_time' do
          time = resell.start_time + 1.hours
          booking.start_time = time.dup

          expect(booking.take_matching_resell.start_time).to eq time
        end

        it 'should set booking end_time' do
          time = resell.end_time - 1.hours
          booking.end_time = time.dup

          expect(booking.take_matching_resell.end_time).to eq time
        end
      end

      context "reset payment status" do
        before(:each) do
          resell.update(
            billing_phase: Reservation.billing_phases[:billed],
            is_paid: true,
            payment_type: 0,
            amount_paid: resell.price
          )
        end

        it 'should set billing_phase to not_billed' do
          expect(resell.reload.billing_phase).to eq 'billed' # check update
          expect(booking.take_matching_resell.billing_phase).to  eq 'not_billed'
        end

        it 'should set is_paid to false' do
          expect(resell.reload.is_paid).to be_truthy # check update
          expect(booking.take_matching_resell.is_paid).to be_falsey
        end

        it 'should set payment_type to unpaid' do
          expect(booking.take_matching_resell.payment_type).to eq 'unpaid'
        end

        it 'should set amount_paid to zero' do
          expect(booking.take_matching_resell.amount_paid).to eq 0
        end
      end

      context "valid reservation with assigned attributes" do
        it 'should save taken resell without errors' do
          expect{booking.take_matching_resell.save!}.not_to raise_error
        end

        it 'should delete membership_connector after saved' do
          new_reservation = booking.take_matching_resell
          new_reservation.save!
          new_reservation.reload
          expect(new_reservation.membership).to eq nil
        end

        it 'should not delete membership_connector until saved' do
          new_reservation = booking.take_matching_resell
          new_reservation.reload
          expect(new_reservation.membership).not_to eq nil
        end

        it 'should not delete membership' do
          new_reservation = booking.take_matching_resell
          new_reservation.save!
          expect{Membership.find(new_reservation.initial_membership_id)}.not_to raise_error
        end
      end
    end

    describe '#resell_to_user' do
      let(:membership) { create :membership }
      let(:resell) { create :reservation,
                            reselling: true,
                            booking_type: :membership,
                            membership: membership,
                            user: membership.user,
                            court: membership.venue.courts.first }
      let(:new_owner) { create :user }

      context "deny invalid input" do
        it 'should return false if not reselling' do
          resell.reselling = false
          expect(resell.resell_to_user(new_owner)).to be_falsey
        end

        it 'should return false if not recurring' do
          resell.membership = nil

          expect(resell.resell_to_user(new_owner)).to be_falsey
        end

        it 'should return false if resold' do
          resell.initial_membership_id = resell.membership.id

          expect(resell.resell_to_user(new_owner)).to be_falsey
        end

        it 'should return false if new owner is blank' do
          expect(resell.resell_to_user(nil)).to be_falsey
        end

        it 'should return false if new owner is not User' do
          expect(resell.resell_to_user(Reservation.new())).to be_falsey
        end
      end

      context "assign params to takeover ownership" do
        it 'should set :user to new user' do
          resell.resell_to_user(new_owner)
          expect(resell.user).to eq new_owner
        end

        it 'should be saved' do
          expect(resell.resell_to_user(new_owner)).to be_truthy
          expect(resell.reload.user).to eq new_owner
        end
      end

      context "assign params to make reservation resold and reversible" do
        it 'should set initial membership to previous membership' do
          initial_membership = resell.membership
          resell.resell_to_user(new_owner)

          expect(resell.initial_membership_id).to eq initial_membership.id
        end
      end

      context "assign params to make resell like usual reservation" do
        it 'should set online booking type' do
          resell.resell_to_user(new_owner)
          expect(resell.booking_type).to eq :online.to_s
        end

        it 'should set reselling to false' do
          resell.resell_to_user(new_owner)
          expect(resell.reselling).to be_falsey
        end

        it 'should delete membership_connector' do
          resell.resell_to_user(new_owner)
          resell.reload
          expect(resell.membership).to eq nil
        end

        it 'should not delete membership' do
          resell.resell_to_user(new_owner)

          expect{Membership.find(resell.initial_membership_id)}.not_to raise_error
        end
      end

      context "reset payment status" do
        before(:each) do
          resell.update(
            billing_phase: Reservation.billing_phases[:billed],
            is_paid: true,
            payment_type: 0,
            amount_paid: resell.price
          )
          resell.resell_to_user(new_owner)
        end

        it 'should set billing_phase to not_billed' do
          expect(resell.billing_phase).to eq 'not_billed'
        end

        it 'should set is_paid to false' do
          expect(resell.is_paid).to be_falsey
        end

        it 'should set payment_type to unpaid' do
          expect(resell.payment_type).to eq 'unpaid'
        end

        it 'should set amount_paid to zero' do
          expect(resell.amount_paid).to eq 0
        end
      end
    end

    describe "#pass_back_to_initial_owner" do
      let!(:venue) { create :venue, :with_courts, :with_users, court_count: 1, user_count: 1, allow_overlapping_resell: true }
      let!(:user) { venue.users.first }
      let!(:court) { venue.courts.first }
      let(:start_time) { Time.current.advance(weeks: 2).change(hour: 10).utc }
      let(:membership) { create :membership,
                                user: user,
                                venue: venue,
                                start_time: start_time,
                                end_time: start_time.advance(weeks: 1, hours: 2) }
      let(:resell) { create :reservation,
                            reselling: true,
                            booking_type: :membership,
                            membership: membership,
                            user: user, court: court,
                            start_time: membership.start_time,
                            end_time: membership.start_time + 2.hours }
      let(:booking) { build :reservation,
                            court: resell.court,
                            start_time: resell.start_time + 30.minutes,
                            end_time: resell.end_time - 30.minutes,
                            price: resell.price + 7 }
      let(:reservation) { booking.take_matching_resell }

      let(:initial_invoice) { create :invoice,
                                        owner: membership.user,
                                        company: membership.venue.company,
                                        is_draft: true,
                                        billing_time: Time.current,
                                        invoice_components: InvoiceComponent.build_from([resell]) }

      context 'base attributes' do
        before(:each) do
          reservation.save # takes resell and converts to resold
          reservation.reload
        end

        context "pass back ownership" do
          it 'should set user to initial user' do
            expect(reservation.user).not_to eq membership.user

            reservation.pass_back_to_initial_owner

            expect(reservation.user).to eq membership.user
          end
        end

        context "lift resold status" do
          it 'should set initial_membership to nil' do
            reservation.pass_back_to_initial_owner

            expect(reservation.initial_membership_id).to be_nil
          end

          it 'should connect to initial membership' do
            reservation.pass_back_to_initial_owner

            expect(reservation.membership).to eq membership
          end
        end

        context "restore reservation to original resell" do
          it 'should set price to membership price' do
            price = reservation.price
            reservation.pass_back_to_initial_owner

            expect(reservation.price).not_to eq price
            expect(reservation.price).to eq membership.price
          end

          it 'should set booking_type to membership' do
            reservation.pass_back_to_initial_owner

            expect(reservation.booking_type).to eq :membership.to_s
          end

          it 'should set refunded to false' do
            reservation.pass_back_to_initial_owner

            expect(reservation.refunded).to be_falsey
          end

          it 'should set reselling to true' do
            reservation.pass_back_to_initial_owner

            expect(reservation.reselling).to be_truthy
          end
        end
      end

      context "restore initial timings" do
        before(:each) do
          reservation.save
          reservation.reload
          reservation.pass_back_to_initial_owner.reload
        end

        it 'should set booking start_time' do
          expect(reservation.start_time).to eq resell.start_time
          expect(reservation.start_time.to_s(:time)).to eq membership.start_time.to_s(:time)
        end

        it 'should set booking end_time' do
          expect(reservation.end_time).to eq resell.end_time
          expect(reservation.end_time.to_s(:time)).to eq membership.end_time.to_s(:time)
        end
      end

      context "restore payment status from invoice" do
        context 'restore billed status' do
          before(:each) do
            initial_invoice.send!
            reservation.save # takes resell and converts to resold
            reservation.reload
            reservation.pass_back_to_initial_owner
          end

          it 'should set billing_phase to billed' do
            expect(reservation.billing_phase).to eq 'billed'
          end
        end

        context 'restore paid status' do
          before(:each) do
            initial_invoice.send!
            initial_invoice.mark_paid
            reservation.save # takes resell and converts to resold
            reservation.reload
            reservation.pass_back_to_initial_owner
          end

          it 'should set is_paid to true' do
            expect(reservation.is_paid).to be_truthy
          end

          it 'should set payment_type to paid' do
            expect(reservation.payment_type).to eq 'paid'
          end

          it 'should set amount_paid to membership price' do
            expect(reservation.amount_paid).to eq membership.price
          end
        end
      end

      context 'withdraw credit' do
        let!(:game_pass) { create :game_pass, :available, user: booking.user, venue: venue }

        before(:each) do
          initial_invoice.send!
           # use game pass to pay reservation and create credit
          reservation.assign_attributes(game_pass_id: game_pass.id)
        end

        it 'deletes credit after conversion' do
          reservation.save
          reservation.reload
          expect(Credit.count).to eq 1
          expect(Credit.last.creditable).to eq reservation
          expect{ reservation.pass_back_to_initial_owner }
                  .to change{ Credit.count }.by(-1)
                  .and change{ reservation.reload.game_pass_id }.to(nil)
        end
      end
    end

    describe '#add_credit_to_initial_owner' do
      let!(:admin) { create(:admin, :with_company) }
      let!(:company) { create(:company) }
      let!(:venue) { create :venue, :with_users, :with_courts, user_count: 2, court_count: 1, company: company }
      let!(:user1) { venue.users.first }
      let!(:user2) { venue.users.second }
      let!(:court) { venue.courts.first }
      let!(:membership) { create :membership, user: user1, venue: venue, price: 13 }

      context 'not resold reservation was paid' do
        let!(:reservation) { create :reservation, user: user1, court: venue.courts.first }

        it 'is not called' do
          expect(reservation).not_to receive(:add_credit_to_initial_owner)

          reservation.update_attribute(:is_paid, true)
        end
      end

      context 'resold reservation was paid' do
        let!(:reservation) { create :reservation,
                                    user: user1,
                                    court: court,
                                    membership: membership,
                                    price: 13,
                                    reselling: true }
        let!(:initial_invoice) { create :invoice,
                                        owner: user1,
                                        company: venue.company,
                                        is_draft: true,
                                        billing_time: Time.current,
                                        invoice_components: InvoiceComponent.build_from([reservation]) }
        let(:initial_invoice_component) { initial_invoice.invoice_components.first }

        context 'callback is called if resold was paid' do
          before(:each) do
            reservation.resell_to_user(user2)
          end

          it 'is called if is_paid changed to true' do
            expect(reservation).to receive(:add_credit_to_initial_owner)

            reservation.update_attribute(:is_paid, true)
          end

          it 'is called if payment_type changed to paid' do
            expect(reservation).to receive(:add_credit_to_initial_owner)

            reservation.update_attribute(:payment_type, 0) # paid
          end
        end

        context 'invalid membership/invoice or no initial invoice' do
          before(:each) do
            reservation.resell_to_user(user2)
          end

          it "doesn't fail update and not create credit if initial_membership_id not found" do
            reservation.update_attribute(:initial_membership_id, membership.id + 1)

            expect(Credit).not_to receive(:create!)

            expect{reservation.update!(is_paid: true)}.not_to raise_error
            expect(reservation.reload.is_paid).to be_truthy
          end

          it "doesn't fail update and not create credit if initial owner not found" do
            membership.update_attribute(:user_id, nil)

            expect(Credit).not_to receive(:create!)

            expect{reservation.update!(is_paid: true)}.not_to raise_error
            expect(reservation.reload.is_paid).to be_truthy
          end

          it "doesn't fail update and not create credit if initial invoice component not found" do
            initial_invoice_component.delete

            expect(Credit).not_to receive(:create!)

            expect{reservation.update!(is_paid: true)}.not_to raise_error
            expect(reservation.reload.is_paid).to be_truthy
          end

          it "doesn't fail update and not create credit if initial invoice not found" do
            initial_invoice_component.update_attribute(:invoice_id, nil)

            expect(Credit).not_to receive(:create!)

            expect{reservation.update!(is_paid: true)}.not_to raise_error
            expect(reservation.reload.is_paid).to be_truthy
          end
        end

        context 'resold after creating draft and before sending or paying invoice' do
          before(:each) do
            reservation.resell_to_user(user2)
            # stub mailer
            allow(InvoiceMailer).to receive_message_chain(:invoice_email, :deliver_later!)
          end

          it 'adds balance to initial owner credit if draft' do
            reservation.update_attribute(:is_paid, true)

            expect(Credit.count).to eq 1

            credit = Credit.last

            expect(credit.balance).to eq initial_invoice_component.price
            expect(company.user_credit_balance(user1)).to eq initial_invoice_component.price
          end

          it 'adds balance to initial owner credit if unpaid' do
            initial_invoice.send!
            reservation.update_attribute(:is_paid, true)
            expect(Credit.count).to eq 1

            credit = Credit.last
            expect(credit.balance).to eq initial_invoice_component.price
            expect(company.user_credit_balance(user1)).to eq initial_invoice_component.price
          end

          it 'adds balance to initial owner credit if paid' do
            initial_invoice.send!
            initial_invoice.mark_paid
            reservation.update_attribute(:is_paid, true)
            expect(Credit.count).to eq 1

            credit = Credit.last
            expect(credit.balance).to eq initial_invoice_component.price
            expect(company.user_credit_balance(user1)).to eq initial_invoice_component.price
          end
        end

        context 'resold after invoice was paid' do
          it 'adds balance to initial owner credit' do
            initial_invoice.send!
            initial_invoice.mark_paid
            reservation.resell_to_user(user2)
            reservation.update_attribute(:is_paid, true)
            expect(Credit.count).to eq 1

            credit = Credit.last
            expect(credit.balance).to eq initial_invoice_component.price
            expect(company.user_credit_balance(user1)).to eq initial_invoice_component.price
          end
        end
      end
    end
  end

  describe '#recalculate_price_on_save' do
    let!(:reservation) { create :reservation, price: 1000 }
    let!(:court) { create :court, :with_prices, venue: reservation.venue }
    subject { reservation.update(params) }
    context 'without flag' do
      let(:params) { { court_id: court.id } }

      it 'does not update price' do
        expect { subject }.to do_not_change { reservation.reload.price }.
          and change { reservation.reload.court }.to(court)
        is_expected.to be_truthy
      end
    end

    context 'with flag' do
      let(:params) { { court_id: court.id, recalculate_price_on_save: true } }

      it 'updates the price' do
        expect { subject }.to change { reservation.reload.price }.to(10).
            and change { reservation.reload.court }.to(court)
        is_expected.to be_truthy
      end
    end
  end

  describe "#write_log" do
    let(:participant) { create :user }
    let(:reservation) { build :reservation, participants: [participant]}

    it "should log reservation after save" do
      expect{reservation.save}.to change { ReservationsLog.count }.by(1)
      expect(reservation.logs.last.params[:participants]).not_to be_empty
    end
  end

  describe 'booking mail' do
    let(:company) { create :company, copy_booking_mail_to: copy_booking_mail_to }
    let(:copy_booking_mail_to) { '' }
    let(:venue) { create :venue, company: company }
    let(:court) { create :court, :with_prices, venue: venue }
    let(:reservation) { build :reservation, court: court, override_should_send_emails: override_should_send_emails }
    let(:override_should_send_emails) { nil }

    subject { reservation.save }

    context 'without copy_booking_mail_to' do
      it 'sends booking email to user only' do
        expect{ subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.last.to).to eq [reservation.user.email]
      end
    end

    context 'with copy_booking_mail_to' do
      let(:copy_booking_mail_to) { 'admin@.test.test, admin2@.test.test' }

      it 'sends booking email to user and admin' do
        expect{ subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        expect(ActionMailer::Base.deliveries.last.to).to match_array(copy_booking_mail_to.split(', '))
      end


      context 'with overridden parameter turned off' do
        let(:override_should_send_emails) { false }

        it 'sends no emails' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end

  describe 'update mail' do
    let!(:company) { create :company }
    let!(:venue) { create :venue, company: company }
    let!(:court) { create :court, venue: venue }
    let!(:coach) { create :coach, :available, for_court: court, company: company }
    let!(:reservation) { create :reservation, court: court, coaches: [coach] }

    subject do
      reservation.update end_time: reservation.end_time + 1.hour,
        override_should_send_emails: override_should_send_emails
    end
    let(:override_should_send_emails) { nil }

    it 'sends emails to an owner and a coach' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
    end

    context 'with disabled company level email' do
      before { company.email_notifications.put(:reservation_updated, false) }

      it 'does not send any emails' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)
      end

      context 'with overridden parameter (turned on)' do
        let(:override_should_send_emails) { true }

        it 'sends emails to an owner and a coach' do
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end
      end
    end

    context 'with overridden parameter (turned off)' do
      let(:override_should_send_emails) { false }

      it 'does not send any emails' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end

  describe '#before_create  :calculate_salary' do
    let(:company) { create :company }
    let(:venue) { create :venue, :with_courts, company: company, court_counts: 1 }
    let(:court) { venue.courts.first }

    context 'with coach' do
      subject do
        create :reservation, court: court,
                             coaches: [coach],
                             start_time: start_time,
                             end_time: end_time
      end

      let(:coach) { create :coach, company: company }
      let!(:price_rate) do
        create :coach_price_rate, coach: coach, venue: venue, sport_name: court.sport_name
      end
      let(:start_time) { in_venue_tz { price_rate.start_time.in_time_zone } }
      let(:end_time) { in_venue_tz { price_rate.end_time.in_time_zone } }

      it 'creates reservation with 1 hour length' do
        is_expected.to be_persisted
        expect(subject.hours).to eq 1
      end

      context 'without salary rates' do
        it 'adds zero salary' do
          expect(subject.coach_salary(coach)).to be_zero
        end
      end

      context 'with salary rates' do
        let(:common_params) { { coach: coach, venue: venue, sport_name: court.sport_name } }
        context 'with covering salary rates' do
          let!(:salary_rate1) do
            create :coach_salary_rate, :all_weeks, rate: 10,
                                       start_time: start_time,
                                       end_time: end_time.advance(minutes: -30),
                                       **common_params
          end
          let!(:salary_rate2) do
            create :coach_salary_rate, :all_weeks, rate: 20,
                                       start_time: end_time.advance(minutes: -30),
                                       end_time: end_time,
                                       **common_params
          end

          it 'adds combined salary' do
            expect(subject.coach_salary(coach)).to eq 15
          end
        end

        context 'with partially covaring rate' do
          let!(:salary_rate) do
            create :coach_salary_rate, :all_weeks, rate: 10,
                                       start_time: start_time,
                                       end_time: end_time.advance(minutes: -30),
                                       **common_params
          end

          it 'adds partial salary' do
            expect(subject.coach_salary(coach)).to eq 5
          end
        end

        context 'with widely overlapping rate' do
          let!(:salary_rate) do
            create :coach_salary_rate, :all_weeks, rate: 13,
                                       start_time: start_time.advance(hours: -1),
                                       end_time: end_time.advance(hours: 1),
                                       **common_params
          end

          it 'calculates only reservation hours' do
            expect(subject.coach_salary(coach)).to eq 13
          end
        end
      end
    end
  end

  describe 'payment type' do
    let!(:reservation) { create :reservation, amount_paid: start_with_amount_paid, price: price }
    let(:price) { 100 }

    subject { reservation.update amount_paid: amount_paid }

    context 'when amount paid is equal to price' do
      let(:amount_paid) { price }
      let(:start_with_amount_paid) { 0 }

      it 'changes payment status to paid' do
        expect { subject }.to change { reservation.reload.payment_type }.to('paid')
      end
    end

    context 'when amount paid is just a little bit' do
      let(:amount_paid) { price * 0.5 }
      let(:start_with_amount_paid) { price }

      it 'changes payment status to semi paid' do
        reservation
        expect { subject }.to change { reservation.reload.payment_type }.to('semi_paid')
      end

    end

    context 'when amount paid is zero' do
      let(:amount_paid) { 0 }
      let(:start_with_amount_paid) { price }

      it 'changes payment status to paid' do
        expect { subject }.to change { reservation.reload.payment_type }.to('unpaid')
      end

    end
  end

  describe 'destroying' do
    let!(:court) { create :court }
    let!(:coach) { create :coach, :available, for_court: court }
    let!(:reservation) { create :reservation, court: court, coaches: [coach] }

    subject { reservation.destroy }

    it 'removes the link between reservation and coach' do
      expect { subject }.to change { Reservation::CoachConnection.count }.by(-1)
    end

    it 'does not touch the coach' do
      expect { subject }.not_to change { Coach.count }
    end
  end
end
