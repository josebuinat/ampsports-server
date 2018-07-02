require 'rails_helper'

describe ReservationSanitizer do
  describe '#create_reservations' do
    subject { ReservationSanitizer.new(user, params).create_reservations }
    let!(:user) { create :user }
    let!(:venue) { create :venue, :with_courts }
    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }
    let(:first_court) { venue.courts.first }
    let(:last_court) { venue.courts.last }

    let(:params) do
      {
        duration: 60,
        date: start_time.to_s(:date),
        pay: pay_bookings,
        card: card_token,
        bookings: bookings_params.to_json
      }
    end
    let(:pay_bookings) { '' }
    let(:card_token) { '' }

    let(:bookings_params) do
      [
        {
          id: first_court.id,
          start_time: start_time.to_s
        }
      ]
    end


    before(:each) do
      # stub segment
      allow(SegmentAnalytics).to receive(:booking)
      allow(SegmentAnalytics).to receive(:unpaid_booking)
    end

    context 'with a valid booking' do
      it 'should return created reservations' do
        is_expected.not_to eq nil
        expect(subject.sort_by(&:id)).to eq Reservation.all.to_a.sort_by(&:id)
      end

      it 'should belong to user' do
        expect(subject.first.user).to eq user
      end

      it 'should connect user to venue' do
        subject

        expect(VenueUserConnector.all.count).to eq 1
        expect(VenueUserConnector.first.user).to eq user
        expect(VenueUserConnector.first.venue).to eq venue
      end

      it 'should use start_time' do
        expect(subject.first.start_time).to eq start_time
      end

      it 'should calculate end time with base duration' do
        expect(subject.first.end_time).to eq start_time + 60.minutes
      end

      it 'should calculate end time with per-booking duration' do
        bookings = JSON.parse(params[:bookings])
        bookings.first[:duration] = 90
        params[:bookings] = bookings.to_json

        expect(subject.first.end_time).to eq start_time + 90.minutes
      end

      it 'should belong to court' do
        expect(subject.first.court).to eq first_court
      end

      it 'should set online booking type' do
        expect(subject.first.booking_type).to eq 'online'
      end

      it 'should set unpaid payment type' do
        expect(subject.first.payment_type).to eq 'unpaid'
      end

      context 'price and discount' do
        it 'should calculate price without discount' do
          price = first_court.price_at(start_time, start_time + 60.minutes, nil)

          expect(subject.first.price).to eq price
        end

        it 'should calculate price with discount' do
          discount = create(:discount, venue: venue)
          user.discounts << discount

          price = first_court.price_at(start_time, start_time + 60.minutes, discount)

          expect(subject.first.price).to eq price
        end
      end

      context 'multiple reservations' do

        it 'should create reservations with same time but different courts' do
          params[:bookings] = [
            { start_time: start_time.to_s, id: first_court.id },
            { start_time: start_time.to_s, id: last_court.id },
          ].to_json

          is_expected.not_to eq nil
          expect(Reservation.all.count).to eq 2
        end

        it 'should create reservations with different time but same court' do
          params[:bookings] = [
            { start_time: start_time.to_s, id: first_court.id },
            { start_time: start_time.advance(hours: 2).to_s, id: first_court.id },
          ].to_json

          is_expected.not_to eq nil
          expect(Reservation.all.count).to eq 2
        end

        it 'should not create duplicating user-venue connections' do
          params[:bookings] = [
            { start_time: start_time.to_s, id: first_court.id },
            { start_time: start_time.advance(hours: 1).to_s, id: first_court.id },
          ].to_json

          subject

          expect(VenueUserConnector.all.count).to eq 1
        end

        context 'that follow each other in time' do
          it 'should be grouped into 1 reservation' do
            params[:bookings] = [
              { start_time: start_time.to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 2).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 1).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 3).to_s, id: first_court.id }
            ].to_json

            is_expected.not_to eq nil
            expect(Reservation.all.count).to eq 1
            expect(Reservation.first.end_time).to eq start_time.advance(hours: 4)
            expect(Reservation.first.price).to eq 40
          end

          it 'should be grouped into several larger reservations if only some are consecutive in time' do
            params[:bookings] = [
              { start_time: start_time.to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 3).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 1).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 4).to_s, id: first_court.id }
            ].to_json

            is_expected.not_to eq nil
            expect(Reservation.all.count).to eq 2
            expect(Reservation.first.price).to eq 20
            expect(Reservation.last.price).to eq 20
          end

          it 'should be grouped into 1 reservation even if they have different durations' do
            params[:bookings] = [
              { start_time: start_time.to_s, id: first_court.id, duration: 120 },
              { start_time: start_time.advance(hours: 2).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 3).to_s, id: first_court.id },
            ].to_json

            is_expected.not_to eq nil
            expect(Reservation.all.count).to eq 1
          end

          it 'should be grouped into several larger reservation if they belong to different courts' do
            params[:bookings] = [
              { start_time: start_time.to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 2).to_s, id: first_court.id },
              { start_time: start_time.advance(hours: 3).to_s, id: first_court.id },
              { start_time: start_time.to_s, id: last_court.id },
              { start_time: start_time.advance(hours: 2).to_s, id: last_court.id },
              { start_time: start_time.advance(hours: 3).to_s, id: last_court.id },
            ].to_json

            is_expected.not_to eq nil
            expect(Reservation.all.count).to eq 4
          end

          context 'and have invalid params' do
            let(:built_reservations) { ReservationSanitizer.new(user, params).build_reservations }

            it 'should not be grouped' do
              params[:bookings] = [
                { start_time: start_time.to_s, id: first_court.id },
                { start_time: start_time.advance(hours: 1).to_s, id: first_court.id },
                { start_time: start_time.advance(hours: 2).to_s, id: '' }
              ].to_json

              expect(built_reservations.length).to eq 3
            end
          end
        end

        context 'taking reselling reservation' do
          let(:membership) { create :membership, user: user, venue: venue }
          let(:start_time) do
            in_venue_tz do
              TimeSanitizer.output(membership.end_time.advance(days: -1).at_noon)
            end
          end
          let(:resell) { create :reservation,
                                reselling: true,
                                booking_type: :membership,
                                membership: membership,
                                user: membership.user,
                                court: first_court,
                                start_time: start_time,
                                end_time: start_time + 2.hours
          } # resell is longer than booking

          context 'venue.allow_overlapping_resell is true' do
            before(:each) do
              venue.update_attribute(:allow_overlapping_resell, true)
            end

            it 'takes reselling reservation for booking' do
              params[:bookings] = [
                { start_time: resell.start_time.to_s, id: first_court.id }
              ].to_json

              is_expected.not_to eq nil
              expect(subject.first.id).to eq resell.id
            end

            it 'does not double take reselling reservation for two overlapping it bookings' do
              params[:bookings] = [
                { start_time: resell.start_time.to_s, id: first_court.id},
                { start_time: resell.start_time.advance(hours: 2).to_s, id: first_court.id},
              ].to_json

              is_expected.not_to eq nil
              expect(Reservation.all.count).to eq 2
              expect(subject.first.id).not_to eq subject.second.id
              expect(subject.first.id).to eq resell.id
            end

            context 'when reselling reservation start time is in the past' do
              before do
                # booking starts at 60 minutes after the resell's start time
                params[:bookings] = [
                  { start_time: resell.start_time.advance(hours: 1).to_s, id: first_court.id},
                ].to_json

                # current time is frozen at 30 minutes after the resell's start time
                allow(Time).to receive(:current).and_return(resell.start_time.advance(minutes: 30))
              end

              it 'takes reselling reservation for booking' do
                expect(resell.start_time).to be < Time.current # just check time mocking
                is_expected.not_to eq nil
                expect(subject.first.id).to eq resell.id
              end
            end
          end
        end
      end

      context 'with payment' do
        let(:pay_bookings) { 'true' }
        let!(:game_pass) { create :game_pass, :available, user: user, venue: venue }

        context 'with game pass' do
          before(:each) { bookings_params.first[:game_pass_id] = game_pass.id }

          it 'returns paid reservation' do
            is_expected.not_to eq nil
            expect(subject.first).to be_paid
          end

          it 'uses game pass charges and saves game_pass_id to reservation' do
            expect{ subject }.to change{ game_pass.reload.remaining_charges }.by(-1.0)
            expect(subject.first.reload.game_pass_id).to be_present
          end
        end
      end
    end

    context 'with an invalid booking' do
      let!(:invalid_start_time) do
        in_venue_tz { Time.current.advance(days: -1).at_noon }
      end
      let(:bookings_params) do
        [
          { start_time: start_time.to_s, id: first_court.id}, # valid
          { start_time: invalid_start_time.to_s, id: first_court.id }, # invalid
        ]
      end

      it 'should return nil if any reservation is invalid' do
        is_expected.to eq nil
      end

      it 'should fail sanitizer validation' do
        sanitizer = ReservationSanitizer.new(user, params)
        sanitizer.create_reservations

        expect(sanitizer.valid?).to be_falsey
      end

      it 'should return reservations errors' do
        sanitizer = ReservationSanitizer.new(user, params)
        sanitizer.create_reservations

        reservation = Reservation.new(
          start_time: invalid_start_time,
          end_time: invalid_start_time + 60.minutes,
          court: first_court,
          user: user,
          price: 1,
        )
        in_venue_tz { reservation.valid? }

        expect(sanitizer.errors.any?).to be_truthy
        expect(sanitizer.errors.keys.first).to eq reservation.name
        expect(sanitizer.errors.values.first).to eq reservation.errors.full_messages
      end

      it 'should not create any reservations' do
        subject

        expect(Reservation.all.count).to eq 0
      end

      it 'should not create any reservations or connectors if have overlapping reservations' do
        params[:bookings] = [
          { start_time: start_time.to_s, id: first_court.id },
          { start_time: start_time.to_s, id: first_court.id },
        ].to_json

        is_expected.to eq nil
        expect(Reservation.all.count).to eq 0
        expect(VenueUserConnector.all.count).to eq 0
      end

      it 'should handle invalid court' do
        params[:bookings] = [
          { start_time: start_time.to_s, id: '' },
          { start_time: start_time.advance(days: 1).to_s, id: '' },
        ].to_json

        is_expected.to eq nil
        expect(Reservation.all.count).to eq 0
      end

      it 'should handle invalid time' do
        params[:bookings] = [
          { start_time: '', id: first_court.id },
          { start_time: '', id: first_court.id },
        ].to_json

        is_expected.to eq nil
        expect(Reservation.all.count).to eq 0
      end

      context 'date limit policy' do
        let(:start_time) { in_venue_tz { Time.current.at_noon } }
        let(:booking_ahead_limit) {venue.booking_ahead_limit}

        it 'should be invalid when date after booking_ahead_limit' do
          params[:bookings] = [
            {
              start_time: start_time.advance(days: booking_ahead_limit).to_s,
              id: first_court.id
            }
          ].to_json

          is_expected.to eq nil
          expect(Reservation.all.count).to eq 0
        end

        it 'should be valid when date before booking_ahead_limit' do
          params[:bookings] = [
            {
              start_time: start_time.advance(days: booking_ahead_limit - 1).to_s,
              id: first_court.id
            }
          ].to_json

          is_expected.not_to eq nil
          expect(Reservation.all.count).to eq 1
        end
      end

      context 'with failed payment' do
        subject { ReservationSanitizer.new(user, params) }
        let(:bookings_params)  { [{ start_time: start_time.to_s, id: first_court.id }] }
        let(:pay_bookings) { 'true' }
        let!(:empty_game_pass) { create :game_pass, :available, user: user, venue: venue, remaining_charges: 0 }

        context 'with game pass' do
          context 'when invalid game pass id was sent' do
            before(:each) do
              bookings_params.first[:game_pass_id] = 'invalid id'
            end

            it 'does not create reservation' do
              expect{ subject.create_reservations }.not_to change{ Reservation.count }
            end

            it 'does not use any game pass charges' do
              expect{ subject.create_reservations }.not_to change{ empty_game_pass.reload.remaining_charges }
              expect(subject).not_to be_valid
            end

            it 'adds game pass error' do
              subject.create_reservations
              error = "Game pass #{I18n.t('errors.reservation.game_pass.not_found')}"
              expect(subject.errors.first[1]).to include(error)
            end
          end

          context 'when game pass is unavailable' do
            before(:each) do
              bookings_params.first[:game_pass_id] = empty_game_pass.id
            end

            it 'does not create reservation or use any game pass charges' do
              expect{ subject.create_reservations }.not_to change{ empty_game_pass.reload.remaining_charges }
              expect(subject).not_to be_valid
            end

            it 'adds game pass error' do
              subject.create_reservations
              error = "Game pass #{I18n.t('errors.reservation.game_pass.not_available')}"
              expect(subject.errors.first[1]).to include(error)
            end
          end
        end
      end
    end
  end
end
